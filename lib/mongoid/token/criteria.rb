module Mongoid
  module Token
    module Criteria
      def find_by_token(token)
        self.find_by(token_options.field_name.to_sym => token)
      end

      def find(*args)
        looks_like_token?(args.first) ? find_by_token(args.first) : super
      end

      private
      def looks_like_token?(token)
        token =~ @@mongoid_token_options.pattern
      end
    end
  end
end
