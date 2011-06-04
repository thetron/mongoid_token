$: << File.expand_path("../../lib", __FILE__)

require 'database_cleaner'
require 'mongoid'
require 'mongoid-rspec'
require 'mongoid_publishable'

RSpec.configure do |config|
  config.include Mongoid::Matchers
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

Mongoid.configure do |config|
  config.master = Mongo::Connection.new.db("mongoid_publishable_test")
end

