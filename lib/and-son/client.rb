require 'ostruct'
require 'sanford-protocol'
require 'and-son/connection'

module AndSon

  module CallRunnerMethods

    # define methods here to allow configuring call runner params.  be sure to
    # use `tap` to return whatever instance `self.call_runner` returns so you
    # can method-chain.  `self.call_runner` returns a new runner instance if
    # called on a client, but returns the chained instance if called on a runner

    def timeout(seconds)
      self.call_runner.tap{|r| r.timeout_value = seconds.to_f}
    end

  end

  class Client < Struct.new(:host, :port, :version)
    include CallRunnerMethods

    DEFAULT_TIMEOUT = 60 #seconds

    # proxy the call method to the call runner
    def call(*args, &block); self.call_runner.call(*args, &block); end

    def call_runner
      # always start with this default CallRunner
      CallRunner.new({
        :host    => host,
        :port    => port,
        :version => version,
        :timeout_value => (ENV['ANDSON_TIMEOUT'] || DEFAULT_TIMEOUT).to_f
      })
    end
  end

  class CallRunner < OpenStruct # {:host, :port, :version, :timeout_value}
    include CallRunnerMethods

    # chain runner methods by returning itself
    def call_runner; self; end

    def call(name, params = {})
      AndSon::Connection.new(host, port).open do |connection|
        connection.write(Sanford::Protocol::Request.new(version, name, params).to_hash)
        Sanford::Protocol::Response.parse(connection.read(timeout_value))
      end
    end
  end

end
