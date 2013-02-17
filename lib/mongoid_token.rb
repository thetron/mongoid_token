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
        #options[:key] ||= false

        self.field options[:field_name].to_sym, :type => String
        self.index({ options[:field_name].to_sym => 1 }, { :unique => true })

        #if options[:key]
        #  self.key options[:field_name].to_sym
        #end

        set_callback(:create, :before) do |document|
          document.create_token(options[:length], options[:contains])
        end

        set_callback(:save, :before) do |document|
          document.create_token_if_nil(options[:length], options[:contains])
        end

        after_initialize do # set_callback did not work with after_initialize callback
          self.instance_variable_set :@max_collision_retries, options[:retry]
          self.instance_variable_set :@token_field_name, options[:field_name]
          self.instance_variable_set :@token_length, options[:length]
          self.instance_variable_set :@token_contains, options[:contains]
        end

        if options[:retry] > 0
          alias_method_chain :insert, :safety
          alias_method_chain :upsert, :safety
        end

        self.class_variable_set :@@token_field_name, options[:field_name]
      end

      def find_by_token(token)
        field_name = self.class_variable_get :@@token_field_name
        self.find_by(field_name.to_sym => token)
      end
    end

    def to_param
      self.send(@token_field_name.to_sym) || super
    end

    protected

    def resolve_token_collisions
      retries = @max_collision_retries

      begin
        yield
      rescue Moped::Errors::OperationFailure => e
        # This is horrible, but seems to be the only way to get the details of the exception?
        continue unless [11000, 11001].include?(e.details['code'])
        continue unless   e.details['err'] =~ /dup key/ &&
                          e.details['err'] =~ /"#{self.send(@token_field_name.to_sym)}"/

        if (retries -= 1) > 0
          self.create_token(@token_length, @token_contains)
          retry
        else
          Rails.logger.warn "[Mongoid::Token] Warning: Maximum to generation retries (#{@max_collision_retries}) exceeded." if defined?(Rails) && Rails.env == 'development'
          raise Mongoid::Token::CollisionRetriesExceeded.new(self, @max_collision_retries)
        end
      end
    end

    def insert_with_safety(options = {})
      resolve_token_collisions { with(:safe => true).insert_without_safety(options) }
    end

    def upsert_with_safety(options = {})
      resolve_token_collisions { with(:safe => true).upsert_without_safety(options) }
    end

    def create_token(length, characters)
      self.send(:"#{@token_field_name}=", self.generate_token(length, characters))
    end

    def create_token_if_nil(length, characters)
      if self[@token_field_name.to_sym].blank?
        self.create_token(length, characters) 
      end
    end

    def generate_token(length, characters = :alphanumeric)
      case characters
      when :alphanumeric
        (1..length).collect { (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }.join
      when :numeric
        rand(10**length).to_s
      when :fixed_numeric
        rand(10**length).to_s.rjust(length,rand(10).to_s)
      when :fixed_numeric_not_null
        (rand(10**length - 10**(length-1)) + 10**(length-1)).to_s
      when :alpha
        Array.new(length).map{['A'..'Z','a'..'z'].map{|r|r.to_a}.flatten[rand(52)]}.join
      end
    end
  end
end
