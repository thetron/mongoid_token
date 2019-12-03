# frozen_string_literal: true

module Mongoid
  module Token
    class Options
      PATTERNS = {
        alphanumeric: ->(length) { "%s#{length}" },
        alpha: ->(length) { "%w#{length}" },
        alpha_upper: ->(length) { "%C#{length}" },
        alpha_lower: ->(length) { "%c#{length}" },
        numeric: ->(length) { "%d1,#{length}" },
        fixed_numeric: ->(length) { "%d#{length}" },
        fixed_numeric_no_leading_zeros: ->(length) { "%D#{length}" },
        fixed_hex_numeric: ->(length) { "%h#{length}" },
        fixed_hex_numeric_no_leading_zeros: ->(length) { "%H#{length}" }
      }.freeze

      def initialize(options = {})
        @options = merge_defaults validate_options(options)
      end

      def length
        @options[:length]
      end

      def retry_count
        @options[:retry_count]
      end

      def contains
        @options[:contains]
      end

      def field_name
        !@options[:id] && @options[:field_name] || :_id
      end

      def skip_finders?
        @options[:skip_finders]
      end

      def override_to_param?
        @options[:override_to_param]
      end

      def generate_on_init
        @options[:id] || @options[:generate_on_init]
      end

      def pattern
        @options[:pattern] ||=
          PATTERNS[@options[:contains]].call(@options[:length])
      end

      private

      def validate_options(options)
        if options.key?(:retry)
          warn "Mongoid::Token Deprecation Warning: option `retry` has "\
               "been renamed to `retry_count`. `:retry` will be "\
               "removed in v2.1"
          options[:retry_count] = options[:retry]
        end
        options
      end

      def merge_defaults(options)
        {
          id: false,
          length: 4,
          retry_count: 3,
          contains: :alphanumeric,
          field_name: :token,
          skip_finders: false,
          override_to_param: true,
          generate_on_init: false
        }.merge(options)
      end
    end
  end
end
