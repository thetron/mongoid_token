$: << File.expand_path("../../lib", __FILE__)

require 'database_cleaner'
require 'mongoid'
require 'mongoid-rspec'
require 'mongoid_token'

ENV['MONGOID_ENV'] = "test"

class Document
  include Mongoid::Document
  include Mongoid::Token
end

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
