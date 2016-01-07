require 'mongoid/token/exceptions'
require 'mongoid/token/options'
require 'mongoid/token/generator'
require 'mongoid/token/finders'
require 'mongoid/token/collision_resolver'

module Mongoid
  module Token
    extend ActiveSupport::Concern

    def initialize_copy(source)
      super(source)
      self.token = nil
    end

    module ClassMethods
      def token(*args)
        options = Mongoid::Token::Options.new(args.extract_options!)

        add_token_field_and_index(options)
        add_token_collision_resolver(options)
        set_token_callbacks(options)

        define_custom_finders(options) if options.skip_finders? == false
        override_to_param(options) if options.override_to_param?
      end

      private
      def add_token_field_and_index(options)
        self.field options.field_name, :type => String, :default => default_value(options)
        self.index({ options.field_name => 1 }, { :unique => true, :sparse => true })
      end

      def add_token_collision_resolver(options)
        resolver = Mongoid::Token::CollisionResolver.new(self, options.field_name, options.retry_count)
        resolver.create_new_token = Proc.new do |document|
          document.send(:create_token, options.field_name, options.pattern)
        end
      end

      def define_custom_finders(options)
        Finders.define_custom_token_finder_for(self, options.field_name)
      end

      def set_token_callbacks(options)
        set_callback(:create, :before) do |document|
          document.create_token_if_nil options.field_name, options.pattern
        end

        set_callback(:save, :before) do |document|
          document.create_token_if_nil options.field_name, options.pattern
        end
      end

      def override_to_param(options)
        self.send(:define_method, :to_param) do
          self.send(options.field_name) || super()
        end
      end

      def default_value(options)
        options.generate_on_init && Mongoid::Token::Generator.generate(options.pattern) || nil
      end
    end

    protected
    def create_token(field_name, pattern)
      self.send :"#{field_name.to_s}=", self.generate_token(pattern)
    end

    def create_token_if_nil(field_name, pattern)
      if self[field_name.to_sym].blank?
        self.create_token field_name, pattern
      end
    end

    def generate_token(pattern)
      Mongoid::Token::Generator.generate pattern
    end
  end
end
