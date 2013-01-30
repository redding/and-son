require 'ostruct'
require 'sanford-protocol'
require 'and-son/connection'
require 'and-son/response'
require 'and-son/stored_responses'

module AndSon

  module CallRunnerMethods

    # define methods here to allow configuring call runner params.  be sure to
    # use `tap` to return whatever instance `self.call_runner` returns so you
    # can method-chain.  `self.call_runner` returns a new runner instance if
    # called on a client, but returns the chained instance if called on a runner

    def timeout(seconds)
      self.call_runner.tap{|r| r.timeout_value = seconds.to_f}
    end

    def params(hash = nil)
      if !hash.kind_of?(Hash)
        raise ArgumentError, "expected params to be a Hash instead of a #{hash.class}"
      end
      self.call_runner.tap{|r| r.params_value.merge!(self.stringify_keys(hash)) }
    end

    protected

    def stringify_keys(hash)
      hash.inject({}){|h, (k, v)| h.merge({ k.to_s => v }) }
    end

  end

  class Client
    include CallRunnerMethods

    DEFAULT_TIMEOUT = 60 #seconds

    attr_reader :host, :port, :version, :responses

    def initialize(host, port, version)
      @host, @port, @version = host, port, version
      @responses = AndSon::StoredResponses.new
    end

    # proxy the call method to the call runner
    def call(*args, &block); self.call_runner.call(*args, &block); end

    def call_runner
      # always start with this default CallRunner
      CallRunner.new({
        :host     => host,
        :port     => port,
        :version  => version,
        :timeout_value => (ENV['ANDSON_TIMEOUT'] || DEFAULT_TIMEOUT).to_f,
        :params_value  => {},
        :responses     => @responses,
      })
    end
  end

  class CallRunner < OpenStruct
    # {:host, :port, :version, :timeout_value, :params_value, :responses}
    include CallRunnerMethods

    # chain runner methods by returning itself
    def call_runner; self; end

    def call(name, params = nil)
      params ||= {}
      if !params.kind_of?(Hash)
        raise ArgumentError, "expected params to be a Hash instead of a #{params.class}"
      end
      client_response = self.responses.find(name, params) if ENV['ANDSON_TEST_MODE']
      client_response ||= self.call!(name, params)

      if block_given?
        yield client_response.protocol_response
      else
        client_response.data
      end
    end

    def call!(name, params)
      call_params = self.params_value.merge(params)
      AndSon::Connection.new(host, port).open do |connection|
        connection.write(Sanford::Protocol::Request.new(version, name, call_params).to_hash)
        AndSon::Response.parse(connection.read(timeout_value))
      end
    end

  end

end
