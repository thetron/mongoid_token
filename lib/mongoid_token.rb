require 'mongoid/token/exceptions'

module Mongoid
  module Token
    extend ActiveSupport::Concern

    module ClassMethods
      def token(*args)
        options = args.extract_options!
        options[:length] ||= 4
        options[:retry] ||= 3
        options[:contains] ||= :alphanumeric
        options[:field_name] ||= :token

        self.field options[:field_name].to_sym, :type => String
        self.index options[:field_name].to_sym, :unique => true

        set_callback(:create, :before) do |document|
          document.create_token(options[:length], options[:contains])
        end

        set_callback(:save, :before) do |document|
          document.create_token_if_nil(options[:length], options[:contains])
        end

        set_callback(:save, :after) do |document|
          document.validate_token_uniqueness!(options[:length], options[:contains], options[:retry])
        end
      end

      def find_by_token(token)
        self.first(:conditions => {:token => token})
      end
    end

    module InstanceMethods
      def to_param
        self.token
      end

      protected
      def create_token(length, characters)
        self.token = self.generate_token(length, characters)# while self.token.nil? || self.class.exists?(:conditions => {:token => self.token})
      end

      def validate_token_uniqueness!(length, characters, attempts)
        attempts_remaining = attempts
        if !defined?(@testing_uniqueness)
          @testing_uniqueness = true
          while attempts_remaining > 0 && @testing_uniqueness
            begin
              self.safely.save
              @testing_uniqueness = false
            rescue
              if defined?(Rails) && Rails.env == 'development'
                Rails.logger.warn "[Mongoid::Token] Warning: Duplicate token found, recreating."
              end
              attempts_remaining -= 1
              create_token(length, characters)
            end
          end
        end

        unless attempts_remaining > 0
          raise Mongoid::Token::CollisionRetriesExceeded.new(self, attempts) unless attempts_remaining > 0
        end
      end

      def token_unique?
        self.class.exists?(:conditions => {:token => self.token})
      end

      def create_token_if_nil(length, characters)
        self.create_token(length, characters) if self.token.nil?
      end

      def generate_token(length, characters = :alphanumeric)
        case characters
        when :alphanumeric
          (1..length).collect { (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }.join
        when :numeric
          rand(10**length).to_s
        when :fixed_numeric
          rand(10**length).to_s.rjust(length,rand(10).to_s)
        when :alpha
          Array.new(length).map{['A'..'Z','a'..'z'].map{|r|r.to_a}.flatten[rand(52)]}.join
        end
      end
    end
  end
end
