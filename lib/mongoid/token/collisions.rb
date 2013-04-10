module Mongoid
  module Token
    module Collisions
      def resolve_token_collisions(resolver)
        retries = resolver.retry_count
        begin
          yield
        rescue Moped::Errors::OperationFailure => e
          continue unless is_duplicate_token_error?(e, self, resolver.field_name)

          if (retries -= 1) >= 0
            resolver.create_new_token_for(self)
            retry
          else
            raise_collision_retries_exceeded_error resolver.field_name, resolver.retry_count
          end
        end
      end

      def raise_collision_retries_exceeded_error(field_name, retry_count)
        Rails.logger.warn "[Mongoid::Token] Warning: Maximum token generation retries (#{retry_count}) exceeded on `#{field_name}'." if defined?(Rails)
        raise Mongoid::Token::CollisionRetriesExceeded.new(self, retry_count)
      end

      def is_duplicate_token_error?(err, document, field_name)
        [11000, 11001].include?(err.details['code']) &&
          err.details['err'] =~ /dup key/ &&
          err.details['err'] =~ /"#{document.send(field_name)}"/
      end
    end
  end
end
