$: << File.expand_path("../../lib", __FILE__)

require 'database_cleaner'
require 'mongoid'
require 'mongoid-rspec'
require 'mongoid_token_plus'
require 'mongoid/token_plus/exceptions'

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

Mongoid.load!( File.join(File.dirname(__FILE__), 'mongoid.yml') )
