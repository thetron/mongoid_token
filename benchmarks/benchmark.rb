$: << File.expand_path("../../lib", __FILE__)

require 'database_cleaner'
require 'mongoid'
require 'mongoid_token'
require 'benchmark'

Mongoid.configure do |config|
  config.connect_to("mongoid_token_benchmark")
end

DatabaseCleaner.strategy = :truncation

# start benchmarks

TOKEN_LENGTH = 8

class Link
  include Mongoid::Document
  include Mongoid::Token
  field :url
  token :length => TOKEN_LENGTH, :contains => :alphanumeric
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

Link.destroy_all
Link.create_indexes
num_records = [1, 50, 100, 1000, 2000, 3000, 4000]
puts "-- Alphanumeric token of length #{TOKEN_LENGTH} (#{62**TOKEN_LENGTH} possible tokens)"
Benchmark.bm do |b|
  num_records.each do |qty|
    b.report("#{qty.to_s.rjust(5, " ")} records    "){ qty.times{ create_link(false) } }
    b.report("#{qty.to_s.rjust(5, " ")} records tok"){ qty.times{ create_link } }
    Link.destroy_all
  end
end

