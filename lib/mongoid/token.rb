require 'mongoid/token/exceptions'
require 'mongoid/token/options'
require 'mongoid/token/generator'
require 'mongoid/token/criteria'

module Mongoid
  module Token
    extend ActiveSupport::Concern

    included do
      cattr_accessor :token_options
    end

    module ClassMethods
      include Mongoid::Token::Criteria

      def token(*args)
        self.token_options = Mongoid::Token::Options.new(args.extract_options!)

        self.field token_options.field_name, :type => String
        self.index({ token_options.field_name => 1 }, { :unique => true })

        set_callback(:create, :before) do |document|
          document.create_token(token_options.length, token_options.contains)
        end

        set_callback(:save, :before) do |document|
          document.create_token_if_nil(token_options.length, token_options.contains)
        end

        unless token_options.retry_count.zero?
          alias_method_chain :insert, :safety
          alias_method_chain :upsert, :safety
        end
      end

    end

    def to_param
      self.send(token_options.field_name) || super
    end

    protected

    def resolve_token_collisions
      retries = token_options.retry_count

      begin
        yield
      rescue Moped::Errors::OperationFailure => e
        # This is horrible, but seems to be the only way to get the details of the exception?
        continue unless [11000, 11001].include?(e.details['code'])
        continue unless   e.details['err'] =~ /dup key/ &&
                          e.details['err'] =~ /"#{self.send(token_options.field_name)}"/

        if (retries -= 1) > 0
          self.create_token(token_options.length, token_options.contains)
          retry
        else
          Rails.logger.warn "[Mongoid::Token] Warning: Maximum to generation retries (#{token_options.retry_count}) exceeded." if defined?(Rails) && Rails.env == 'development'
          raise Mongoid::Token::CollisionRetriesExceeded.new(self, token_options.retry_count)
        end
      end
    end

    def insert_with_safety(options = {})
      resolve_token_collisions { with(:safe => true).insert_without_safety(options) }
    end

    def upsert_with_safety(options = {})
      resolve_token_collisions { with(:safe => true).upsert_without_safety(options) }
    end

    def create_token(length, characters)
      self.send(:"#{self.class.token_options.field_name.to_s}=", self.generate_token(length, characters))
    end

    def create_token_if_nil(length, characters)
      if self[self.class.token_options.field_name.to_sym].blank?
        self.create_token(length, characters) 
      end
    end

    def generate_token(length, characters = :alphanumeric)
      Mongoid::Token::Generator.generate(self.class.token_options.pattern)
    end
  end
end
