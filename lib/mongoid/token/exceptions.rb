module Mongoid
  module Token
    class Error < StandardError; end

    class CollisionRetriesExceeded < Error
      def initialize(model, retries)
        @model = model
        @retries = retries
      end

      def to_s
        "Failed to generate unique token for #{@model.to_s} after #{@retries} attempts."
      end
    end
  end
end
