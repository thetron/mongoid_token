require 'mongoid/token/exceptions'
require 'mongoid/token/options'
require 'mongoid/token/generator'
require 'mongoid/token/finders'
require 'mongoid/token/collisions'

module Mongoid
  module Token
    extend ActiveSupport::Concern
    include Collisions

    included do
      cattr_accessor :token_options
    end

    module ClassMethods
      def token(*args)
        self.token_options = Mongoid::Token::Options.new(args.extract_options!)

        self.field token_options.field_name, :type => String
        self.index({ token_options.field_name => 1 }, { :unique => true })

        Finders.create_custom_finder(self, token_options.field_name)
        #Callbacks.configure_resolution_handler(token_options.field_name, token_options.retry_count)

        set_callback(:create, :before) do |document|
          document.create_token(token_options.length, token_options.contains)
        end

        set_callback(:save, :before) do |document|
          document.create_token_if_nil(token_options.length, token_options.contains)
        end
      end
    end

    def to_param
      self.send(token_options.field_name) || super
    end

    protected
    def create_token(length, characters)
      self.send(:"#{self.class.token_options.field_name.to_s}=", self.generate_token(length, characters))
    end

    def create_token_if_nil(length, characters)
      if self[self.class.token_options.field_name.to_sym].blank?
        self.create_token(length, characters) 
      end
    end

    def generate_token(length, characters = :alphanumeric)
      Mongoid::Token::Generator.generate(self.token_options.pattern)
    end
  end
end
