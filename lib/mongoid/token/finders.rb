module Mongoid
  module Token
    module Finders
      def self.define_custom_token_finder_for(klass, field_name = :token)
        klass.define_singleton_method(:"find_by_#{field_name.to_s}") do |token|
          self.find_by(field_name.to_sym => token)
        end

        klass.define_singleton_method :"find_with_#{field_name}" do |*args| # this is going to be painful if tokens happen to look like legal object ids
          args.all?{|arg| BSON::ObjectId.legal?(arg)} ? send(:"find_without_#{field_name}",*args) : klass.send(:"find_by_#{field_name.to_s}", args.first)
        end

        # this craziness taken from, and then compacted into a string class_eval
        # http://geoffgarside.co.uk/2007/02/19/activesupport-alias-method-chain-modules-and-class-methods/
        klass.class_eval("class << self; alias_method_chain :find, :#{field_name} if self.method_defined?(:find); end")
      end
    end
  end
end
