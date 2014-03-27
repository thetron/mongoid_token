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
            down_character(length)
          when 'C'
            up_character(length)
          when 'd'
            digits(length)
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

      def self.down_character(length = 1)
        self.rand_string_from_chars ('a'..'z').to_a, length
      end

      def self.up_character(length = 1)
        self.rand_string_from_chars ('A'..'Z').to_a, length
      end

      def self.integer(length = 1)
        (rand(10**length - 10**(length-1)) + 10**(length-1)).to_s
      end

      def self.digits(length = 1)
        rand(10**length).to_s.rjust(length, "0")
      end

      def self.alpha(length = 1)
        self.rand_string_from_chars (('A'..'Z').to_a + ('a'..'z').to_a), length
      end

      def self.alphanumeric(length = 1)
        (1..length).collect { (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }.join
      end

      def self.punctuation(length = 1)
        self.rand_string_from_chars ['.','-','_','=','+','$'], length
      end
    end
  end
end
