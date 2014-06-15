# proposed pattern options
# %c - lowercase character
# %C - uppercase character
# %d - digit
# %D - non-zero digit / no-leading zero digit if longer than 1
# %s - alphanumeric character
# %w - upper and lower alpha character
# %p - URL-safe punctuation
#
# Any pattern can be followed by a number, representing how many of that type to generate

module Mongoid
  module Token
    module Generator
      REPLACE_PATTERN = /%((?<character>[cCdDpsw]{1})(?<length>\d+(,\d+)?)?)/

      def self.generate(pattern)
        pattern.gsub REPLACE_PATTERN do |match|
          match_data = $~
          type = match_data[:character]
          length = [match_data[:length].to_i, 1].max

          case type
          when 'c'
            alpha(length).downcase
          when 'C'
            alpha(length).upcase
          when 'd'
            numeric(length)
          when 'D'
            integer(length)
          when 's'
            alphanumeric(length)
          when 'w'
            alpha(length)
          when 'p'
            "-"
          end
        end
      end

      private
      def self.rand_string_from_chars(chars, length = 1)
        Array.new(length).map{ chars.sample }.join
      end

      def self.integer(length = 1)
        ('1'..'9').to_a.sample + self.numeric(length - 1)
      end

      def self.numeric(length = 1)
        self.rand_string_from_chars ('0'..'9').to_a, length
      end

      def self.alpha(length = 1)
        self.rand_string_from_chars (('A'..'Z').to_a + ('a'..'z').to_a), length
      end

      def self.alphanumeric(length = 1)
        self.rand_string_from_chars (('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a), length
      end

      def self.punctuation(length = 1)
        self.rand_string_from_chars ['.','-','_','=','+','$'], length
      end
    end
  end
end
