# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'and-son/version'

Gem::Specification.new do |gem|
  gem.name          = "and-son"
  gem.version       = AndSon::VERSION
  gem.authors       = ["Collin Redding"]
  gem.email         = ["collin.redding@me.com"]
  gem.description   = "Generic client for communicating with Sanford service hosts"
  gem.summary       = "Generic client for communicating with Sanford service hosts"
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency("sanford", ["~>0"])

  gem.add_development_dependency("assert",        ["~> 0.8"])
  gem.add_development_dependency("assert-mocha",  ["~> 0.1"])
end
