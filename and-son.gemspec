# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'and-son/version'

Gem::Specification.new do |gem|
  gem.name          = "and-son"
  gem.version       = AndSon::VERSION
  gem.authors       = ["Collin Redding", "Kelly Redding"]
  gem.email         = ["collin.redding@me.com", "kelly@kellyredding.com"]
  gem.summary       = "Simple Sanford client for Ruby."
  gem.description   = "Simple Sanford client for Ruby."
  gem.homepage      = "https://github.com/redding/and-son"
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency("assert", ["~> 2.16.3"])

  gem.add_dependency("sanford-protocol",  ["~> 0.12.0"])

end
