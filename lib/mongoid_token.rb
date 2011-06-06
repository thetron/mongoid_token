module Mongoid
  module Token
    extend ActiveSupport::Concern

    module ClassMethods
      def token(*args)
        options = args.extract_options!
        options[:length] ||= 4
        options[:contains] ||= :alphanumeric
        options[:index] = true unless options.has_key?(:index)

        self.field :token, :type => String
        self.index :token, :unique => true if options[:index]

        set_callback(:create, :before) do |document|
          document.create_token(options[:length], options[:contains])
        end

        set_callback(:save, :before) do |document|
          document.create_token_if_nil(options[:length], options[:contains])
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
        self.token = self.generate_token(length, characters) while self.token.nil? || self.class.exists?(:conditions => {:token => self.token})
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
