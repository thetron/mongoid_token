$: << File.expand_path("../../lib", __FILE__)

require 'database_cleaner'
require 'mongoid'
require 'mongoid-rspec'
require 'mongoid_token'

ENV['MONGOID_ENV'] = "test"

RSpec.configure do |config|
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
  config.sessions = {
    default: {
      database: "mongoid_token_test",
      hosts: [ "localhost:#{ENV['BOXEN_MONGODB_PORT'] || 27017}" ],
      options: {}
    }
  }
end
