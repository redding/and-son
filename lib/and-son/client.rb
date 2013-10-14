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

    attr_reader :host, :port, :responses

    def initialize(host, port)
      @host, @port = host, port
      @responses = AndSon::StoredResponses.new
    end

    # proxy the call method to the call runner
    def call(*args, &block); self.call_runner.call(*args, &block); end

    def call_runner
      # always start with this default CallRunner
      CallRunner.new({
        :host     => host,
        :port     => port,
        :timeout_value => (ENV['ANDSON_TIMEOUT'] || DEFAULT_TIMEOUT).to_f,
        :params_value  => {},
        :logger_value  => NullLogger.new,
        :responses     => @responses,
      })
    end
  end

  class CallRunner < OpenStruct
    # { :host, :port, :timeout_value, :params_value, :logger_value, :responses }
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

      summary_line = SummaryLine.new({
        'time'    => RoundedTime.new(benchmark.real),
        'status'  => client_response.protocol_response.code,
        'host'    => "#{self.host}:#{self.port}",
        'service' => name,
        'params'  => params
      })
      self.logger_value.info("[AndSon] #{summary_line}")

      if block_given?
        yield client_response.protocol_response
      else
        client_response.data
      end
    end

    def call!(name, params)
      call_params = self.params_value.merge(params)
      AndSon::Connection.new(host, port).open do |connection|
        connection.write(Sanford::Protocol::Request.new(name, call_params).to_hash)
        connection.close_write
        if !connection.peek(timeout_value).empty?
          AndSon::Response.parse(connection.read(timeout_value))
        else
          raise AndSon::ConnectionClosedError.new
        end
      end
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

  module SummaryLine
    def self.new(line_attrs)
      attr_keys = %w{time status host service params}
      attr_keys.map{ |k| "#{k}=#{line_attrs[k].inspect}" }.join(' ')
    end
  end

  module RoundedTime
    ROUND_PRECISION = 2
    ROUND_MODIFIER = 10 ** ROUND_PRECISION
    def self.new(time_in_seconds)
      (time_in_seconds * 1000 * ROUND_MODIFIER).to_i / ROUND_MODIFIER.to_f
    end
  end

end
