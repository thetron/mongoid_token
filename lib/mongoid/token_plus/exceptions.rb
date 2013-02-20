module Mongoid
  module TokenPlus
    class Error < StandardError; end

    class CollisionRetriesExceeded < Error
      def initialize(resource = "unknown resource", attempts = "unspecified")
        @resource = resource
        @attempts = attempts
      end

      def to_s
        "Failed to generate unique token for #{@resource} after #{@attempts} attempts."
      end
    end
  end
end
