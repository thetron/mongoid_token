module Mongoid
  module Token
    extend ActiveSupport::Concern

    included do

    end

    module ClassMethods
      def token(*args)
        options = args.extract_options!
        options[:length] ||= 4
        options[:with] ||= :alphanumeric

        self.field :token, :type => String
        self.before_create :generate_token

        set_callback(:create, :before) do |document|
          document.create_token(options[:length], options[:with])
        end
      end
    end

    module InstanceMethods
      def find_by_token(token)
        self.class.where(:conditions => {:token => token}).limit(1)
      end

      def to_param
        self.token
      end

      protected
      def create_token(length, characters)
        self.token = generate_token(length, characters) while self.token == nil || self.class.exists?(:conditions => {:token => self.token})
      end

      def generate_token(length, characters)
        ActiveSupport::SecureRandom.hex(length)[0...length]
      end
    end
  end
end
