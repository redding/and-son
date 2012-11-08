require 'ostruct'

ROOT = File.expand_path('../..', __FILE__)

require 'and-son'

require 'test/support/fake_socket'

if defined?(Assert)
  require 'assert-mocha'
end
