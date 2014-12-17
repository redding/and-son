require 'and-son/call_runner'
require 'and-son/stored_responses'

module AndSon

  module Client

    def self.new(host, port)
      if !ENV['ANDSON_TEST_MODE']
        AndSonClient.new(host, port)
      else
        TestClient.new(host, port)
      end
    end

    def self.included(klass)
      klass.class_eval do
        include CallRunner::InstanceMethods
        include InstanceMethods
      end
    end

    module InstanceMethods

      attr_reader :host, :port

      def initialize(host, port)
        @host, @port = host, port
      end

    end

  end

  class AndSonClient
    include Client

    # proxy the call method to the call runner
    def call(*args, &block); self.call_runner.call(*args, &block); end

    def call_runner
      AndSon::CallRunner.new(host, port)
    end

    def hash
      self.call_runner.hash
    end

    def ==(other)
      other.kind_of?(self.class) ? self.hash == other.hash : super
    end
    alias :eql? :==

  end

  class TestClient
    include Client

    attr_reader :calls, :responses
    attr_reader :before_call_procs, :after_call_procs
    attr_accessor :timeout_value, :params_value, :logger_value

    def initialize(host, port)
      super
      @calls = []
      @responses = AndSon::StoredResponses.new

      @params_value = {}
      @before_call_procs = []
      @after_call_procs  = []
    end

    def call(name, params = nil)
      params ||= {}
      callback_params = self.params_value.merge(params)

      response = self.responses.get(name, params)
      self.before_call_procs.each{ |p| p.call(name, callback_params, self) }
      self.calls << Call.new(name, params, response.protocol_response)
      self.after_call_procs.each{ |p| p.call(name, callback_params, self) }
      if block_given?
        yield response.protocol_response
      else
        response.data
      end
    end

    def call_runner; self; end

    def add_response(name, &block)
      self.responses.add(name, &block)
    end

    def remove_responses(name)
      self.responses.remove(name)
    end

    def reset
      self.calls.clear
      self.responses.remove_all
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

    Call = Struct.new(:request_name, :request_params, :response)

  end

end
