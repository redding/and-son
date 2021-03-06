require 'benchmark'
require 'logger'
require 'sanford-protocol'
require 'and-son/connection'
require 'and-son/response'

module AndSon

  class CallRunner

    DEFAULT_TIMEOUT = 60 # seconds

    attr_reader :host, :port
    attr_reader :before_call_procs, :after_call_procs
    attr_accessor :timeout_value, :params_value, :logger_value

    def initialize(host, port)
      @host = host
      @port = port
      @params_value  = {}
      @timeout_value = (ENV['ANDSON_TIMEOUT'] || DEFAULT_TIMEOUT).to_f
      @logger_value  = NullLogger.new
      @before_call_procs = []
      @after_call_procs  = []
    end

    # chain runner methods by returning itself
    def call_runner; self; end

    def call(name, params = nil)
      params ||= {}
      if !params.kind_of?(Hash)
        raise ArgumentError, "expected params to be a Hash instead of a #{params.class}"
      end
      call_params = self.params_value.merge(params)

      self.before_call_procs.each{ |p| p.call(name, call_params, self) }
      client_response = nil
      benchmark = Benchmark.measure do
        client_response = call!(name, call_params)
      end
      self.after_call_procs.each{ |p| p.call(name, call_params, self) }

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

    def hash
      [ self.host,
        self.port,
        self.timeout_value,
        self.params_value,
        self.logger_value
      ].hash
    end

    def ==(other)
      other.kind_of?(self.class) ? self.hash == other.hash : super
    end
    alias :eql? :==

    private

    def call!(name, params)
      AndSon::Connection.new(host, port).open do |connection|
        connection.write(Sanford::Protocol::Request.new(name, params).to_hash)
        connection.close_write
        if !connection.peek(timeout_value).empty?
          AndSon::Response.parse(connection.read(timeout_value))
        else
          raise AndSon::ConnectionClosedError.new
        end
      end
    end

    module InstanceMethods

      # define methods here to allow configuring call runner params.  be sure to
      # use `tap` to return whatever instance `self.call_runner` returns so you
      # can method-chain.  `self.call_runner` returns a new runner instance if
      # called on a client, but returns the chained instance if called on a runner

      def timeout(seconds)
        self.call_runner.tap{ |r| r.timeout_value = seconds.to_f }
      end

      def params(hash = nil)
        if !hash.kind_of?(Hash)
          raise ArgumentError, "expected params to be a Hash instead of a #{hash.class}"
        end
        self.call_runner.tap{ |r| r.params_value.merge!(stringify_keys(hash)) }
      end

      def logger(passed_logger)
        self.call_runner.tap{ |r| r.logger_value = passed_logger }
      end

      def before_call(&block)
        self.call_runner.tap{ |r| r.before_call_procs << block }
      end

      def after_call(&block)
        self.call_runner.tap{ |r| r.after_call_procs << block }
      end

      private

      def stringify_keys(hash)
        hash.inject({}){|h, (k, v)| h.merge({ k.to_s => v }) }
      end

    end
    include InstanceMethods

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

    class NullLogger
      ::Logger::Severity.constants.each do |name|
        define_method(name.downcase){|*args| } # no-op
      end

      def hash; 1; end
    end

  end

  class ConnectionClosedError < RuntimeError
    def initialize
      super "The server closed the connection, no response was written."
    end
  end

end
