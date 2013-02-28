module Mongoid
  module Token
    module Collisions
      extend ActiveSupport::Concern
      included do
        alias_method_chain :insert, :safety
        alias_method_chain :upsert, :safety
      end

      module ClassMethods
        def configure_resolution_handler()
          # ???????????????
        end
      end

      private
      def insert_with_safety(options = {})
        resolve_token_collisions { with(:safe => true).insert_without_safety(options) }
      end

      def upsert_with_safety(options = {})
        resolve_token_collisions { with(:safe => true).upsert_without_safety(options) }
      end

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
    end
  end
end
