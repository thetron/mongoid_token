require 'mongoid/token/exceptions'
require 'mongoid/token/options'
require 'mongoid/token/generator'
require 'mongoid/token/finders'
require 'mongoid/token/collision_resolver'

module Mongoid
  module Token
    extend ActiveSupport::Concern

    module ClassMethods
      def initialize_copy(source)
        super(source)
        self.token = nil
      end

      def token(*args)
        options = Mongoid::Token::Options.new(args.extract_options!)

        self.field options.field_name, :type => String, :default => nil
        self.index({ options.field_name => 1 }, { :unique => true })

        resolver = Mongoid::Token::CollisionResolver.new(self, options.field_name, options.retry_count)
        resolver.create_new_token = Proc.new do |document|
          document.send(:create_token, options.field_name, options.pattern)
        end

        if options.skip_finders? == false
          Finders.define_custom_token_finder_for(self, options.field_name)
        end

        set_callback(:create, :before) do |document|
          document.create_token options.field_name, options.pattern
        end

        set_callback(:save, :before) do |document|
          document.create_token_if_nil options.field_name, options.pattern
        end

        if options.override_to_param?
          self.send(:define_method, :to_param) do
            self.send(options.field_name) || super(*args)
          end
        end
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
