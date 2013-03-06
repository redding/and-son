require 'benchmark'
require 'logger'
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
      self.call_runner.tap{|r| r.timeout_value = seconds.to_f }
    end

    def params(hash = nil)
      if !hash.kind_of?(Hash)
        raise ArgumentError, "expected params to be a Hash instead of a #{hash.class}"
      end
      self.call_runner.tap{|r| r.params_value.merge!(self.stringify_keys(hash)) }
    end

    def logger(passed_logger)
      self.call_runner.tap{|r| r.logger_value = passed_logger }
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
        :logger_value  => NullLogger.new,
        :responses     => @responses,
      })
    end
  end

  class CallRunner < OpenStruct
    # { :host, :port, :version, :timeout_value, :params_value, :logger_value,
    #   :responses }
    include CallRunnerMethods

    # chain runner methods by returning itself
    def call_runner; self; end

    def call(name, params = nil)
      params ||= {}
      if !params.kind_of?(Hash)
        raise ArgumentError, "expected params to be a Hash instead of a #{params.class}"
      end
      client_response = nil
      benchmark = Benchmark.measure do
        client_response = self.responses.find(name, params) if ENV['ANDSON_TEST_MODE']
        client_response ||= self.call!(name, params)
      end

      self.logger_value.info("[AndSon] #{summary_line(name, params, benchmark, client_response)}")
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
        if !connection.peek(timeout_value).empty?
          AndSon::Response.parse(connection.read(timeout_value))
        else
          raise AndSon::ConnectionClosedError.new
        end
      end
    end

    protected

    def summary_line(name, params, benchmark, client_response)
      response = client_response.protocol_response
      SummaryLine.new.tap do |line|
        line.add 'host',    "#{self.host}:#{self.port}"
        line.add 'version',  self.version
        line.add 'service',  name
        line.add 'params',   params
        line.add 'status',   response.code
        line.add 'duration', self.round_time(benchmark.real)
      end
    end

    ROUND_PRECISION = 2
    ROUND_MODIFIER = 10 ** ROUND_PRECISION
    def round_time(time_in_seconds)
      (time_in_seconds * 1000 * ROUND_MODIFIER).to_i / ROUND_MODIFIER.to_f
    end

  end

  class SummaryLine

    def initialize
      @hash = {}
    end

    def add(key, value)
      @hash[key] = value.inspect if value
    end

    def to_s
      [ 'host', 'version', 'service', 'status', 'duration', 'params' ].map do |key|
        "#{key}=#{@hash[key]}" if @hash[key]
      end.compact.join(" ")
    end

  end

  class ConnectionClosedError < RuntimeError
    def initialize
      super "The server closed the connection, no response was written."
    end
  end

  class NullLogger
    ::Logger::Severity.constants.each do |name|
      define_method(name.downcase){|*args| } # no-op
    end
  end

end
