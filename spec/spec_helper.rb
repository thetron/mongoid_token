$: << File.expand_path("../../lib", __FILE__)

require 'database_cleaner'
require 'mongoid'
require 'mongoid-rspec'
require 'mongoid_token'
require 'mongoid/token/exceptions'

RSpec.configure do |config|
  config.include Mongoid::Matchers
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
  end

  config.after(:each) do
    DatabaseCleaner.clean

    # Added dropping collection to ensure indexes are removed
    Mongoid.master.collections.select do |collection|
      include = collection.name !~ /system/
      include
    end.each(&:drop)
  end
end

Mongoid.configure do |config|
  config.master = Mongo::Connection.new.db("mongoid_token_test")
  config.autocreate_indexes = true
  config.persist_in_safe_mode = true
end

