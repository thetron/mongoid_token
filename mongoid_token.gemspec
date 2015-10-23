# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "version"

Gem::Specification.new do |s|
  s.name        = "mongoid_token"
  s.version     = MongoidToken::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Nicholas Bruning"]
  s.email       = ["nicholas@bruning.com.au"]
  s.homepage    = "http://github.com/thetron/mongoid_token"
  s.licenses    = ['MIT']
  s.summary     = %q{A little random, unique token generator for Mongoid documents.}
  s.description = %q{Mongoid token is a gem for creating random, unique tokens for mongoid documents. Highly configurable and great for making URLs a little more compact.}

  s.rubyforge_project = "mongoid_token"
  s.add_dependency 'mongoid', '~> 5.0.0'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
