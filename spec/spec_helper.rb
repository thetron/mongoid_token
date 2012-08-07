$: << File.expand_path("../../lib", __FILE__)

require 'database_cleaner'
require 'mongoid'
require 'mongoid-rspec'
require 'mongoid_token'
require 'mongoid/token/exceptions'

ENV['MONGOID_ENV'] = "test"

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

Mongoid.load!( File.join(File.dirname(__FILE__), 'mongoid.yml') )
