# frozen_string_literal: true

# proposed pattern options
# %c - lowercase character
# %C - uppercase character
# %d - digit
# %D - non-zero digit / no-leading zero digit if longer than 1
# %s - alphanumeric character
# %w - upper and lower alpha character
# %p - URL-safe punctuation
#
# Any pattern can be followed by a number, representing how many of that type
# to generate

module Mongoid
  module Token
    module Generator
      REPLACE_PATTERN = /%((?<character>[cCdDhHpsw]{1})(?<length>\d+(,\d+)?)?)/
      TYPES = {
        c: ->(length) { down_character(length) },
        C: ->(length) { up_character(length) },
        d: ->(length) { digits(length) },
        D: ->(length) { integer(length) },
        h: ->(length) { digits(length, 16) },
        H: ->(length) { integer(length, 16) },
        s: ->(length) { alphanumeric(length) },
        w: ->(length) { alpha(length) },
        p: ->(_length) { "-" }
      }.freeze

      def self.generate(pattern)
        pattern.gsub REPLACE_PATTERN do
          match = $~
          type = match[:character]
          length = [match[:length].to_i, 1].max

          TYPES[type.to_sym].call(length)
        end
      end

      def self.rand_string_from_chars(chars, length = 1)
        Array.new(length).map { chars.sample }.join
      end

      def self.down_character(length = 1)
        rand_string_from_chars ("a".."z").to_a, length
      end

      def self.up_character(length = 1)
        rand_string_from_chars ("A".."Z").to_a, length
      end

      def self.integer(length = 1, base = 10)
        (rand(base**length - base**(length - 1)) + base**(length - 1)).
          to_s(base)
      end

      def self.digits(length = 1, base = 10)
        rand(base**length).to_s(base).rjust(length, "0")
      end

      def self.alpha(length = 1)
        rand_string_from_chars (("A".."Z").to_a + ("a".."z").to_a), length
      end

      def self.alphanumeric(length = 1)
        (1..length).map do
          i = Kernel.rand(62)
          if i < 10
            i + 48
          else
            i + (i < 36 ? 55 : 61)
          end.chr
        end.join
      end

      def self.punctuation(length = 1)
        rand_string_from_chars %w[. - _ = + $], length
      end
    end
  end
end
