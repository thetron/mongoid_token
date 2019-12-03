# frozen_string_literal: true

require "simplecov"
require "codeclimate-test-reporter"
SimpleCov.start

$: << File.expand_path("../lib", __dir__)

require "database_cleaner"
require "mongoid"
require "mongoid-rspec"
require "mongoid_token"

ENV["MONGOID_ENV"] = "test"

RSpec.configure do |config|
  Mongo::Logger.logger.level = Logger::ERROR

  config.include Mongoid::Matchers
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
  end

  config.after(:each) do
    DatabaseCleaner.clean
    Mongoid.purge!
  end
end

Mongoid.configure do |config|
  config.connect_to("mongoid_token_test", {})
end
