$: << File.expand_path("../../lib", __FILE__)

require 'database_cleaner'
require 'mongoid'
require 'mongoid-rspec'
require 'mongoid_token'
require 'benchmark'

Mongoid.configure do |config|
  config.master = Mongo::Connection.new.db("mongoid_token_benchmark")
end

DatabaseCleaner.strategy = :truncation

# start benchmarks

class Link
  include Mongoid::Document
  include Mongoid::Token
  field :url
  token :length => 2, :contains => :alphanumeric
end

class NoTokenLink
  include Mongoid::Document
  field :url
end

def create_link(token = true)
  if token
    Link.create(:url => "http://involved.com.au")
  else
    NoTokenLink.create(:url => "http://involved.com.au")
  end
end

#create_link # prime DB
Link.destroy_all
num_records = [1, 50, 100, 150, 200, 250]
puts "-- Alphanumeric token of length 2 (3844 possible tokens)"
Benchmark.bm do |b|
  num_records.each do |qty|
    b.report("#{qty.to_s.rjust(5, " ")} records (n)"){ qty.times{ create_link(false) } }
    b.report("#{qty.to_s.rjust(5, " ")} records (t)"){ qty.times{ create_link } }
    Link.destroy_all
  end
end

