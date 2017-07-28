require 'mongoid/token/collisions'

module Mongoid
  module Token
    module SafeOperationsHandler
      def insert(options = {})
        safe_operation { super(options) }
      end

      def upsert(options = {})
        safe_operation { super(options) }
      end

      def safe_operation(&block)
        resolver = self.class.resolvers.first
        resolve_token_collisions(resolver) { with(write: { w: 1 }, &block) }
      end
    end

    class CollisionResolver
      attr_accessor :create_new_token
      attr_reader :klass
      attr_reader :field_name
      attr_reader :retry_count

      def initialize(klass, field_name, retry_count)
        @create_new_token = proc { |doc| }
        @klass = klass
        @field_name = field_name
        @retry_count = retry_count
        klass.send(:include, Mongoid::Token::Collisions)
        klass.send(:prepend, SafeOperationsHandler)
      end

      def create_new_token_for(document)
        @create_new_token.call(document)
      end
    end
  end
end
