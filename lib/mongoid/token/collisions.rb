# frozen_string_literal: true

module Mongoid
  module Token
    module Collisions
      def resolve_token_collisions
        retries = nil
        begin
          yield
        rescue Mongo::Error::OperationFailure => e
          resolver = self.class.resolvers.select do |r|
            duplicate_token_error?(e, self, r.field_name)
          end.first
          raise e unless resolver

          retries ||= resolver.retry_count
          if (retries -= 1) >= 0
            resolver.create_new_token_for(self)
            retry
          end
          raise_collision_retries_exceeded_error(resolver.field_name,
                                                 resolver.retry_count)
        end
      end

      def raise_collision_retries_exceeded_error(field_name, retry_count)
        if defined?(Rails)
          Rails.logger.warn "[Mongoid::Token] Warning: Maximum token "\
                            "generation retries (#{retry_count}) exceeded on "\
                            "`#{field_name}'."
        end
        raise Mongoid::Token::CollisionRetriesExceeded.new(self, retry_count)
      end

      def duplicate_token_error?(err, document, field_name)
        [11_000, 11_001].include?(err.code) &&
          err.message =~ /dup key/ &&
          err.message =~ /"#{document.send(field_name)}"/ &&
          true
      end
    end
  end
end
