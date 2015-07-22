module Mongoid
  module Token
    module Finders
      def self.define_custom_token_finder_for(klass, field_name = :token)
        klass.define_singleton_method(:"find_by_#{field_name}") do |token|
          if token.is_a?(Array)
            self.in field_name.to_sym => token
          else
            self.find_by field_name.to_sym => token
          end
        end
      end
    end
  end
end
