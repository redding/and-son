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

  end

  class TestClient
    include Client

    attr_reader :calls, :responses

    def initialize(host, port)
      super
      @calls = []
      @responses = AndSon::StoredResponses.new
    end

    def call(name, params = nil)
      params ||= {}
      response = self.responses.get(name, params)
      self.calls << Call.new(name, params, response.protocol_response)
      if block_given?
        yield response.protocol_response
      else
        response.data
      end
    end

    def call_runner; self; end

    def add_response(*args, &block)
      self.responses.add(*args, &block)
    end

    def remove_response(*args)
      self.responses.remove(*args)
    end

    def reset
      self.calls.clear
      self.responses.remove_all
    end

    Call = Struct.new(:request_name, :request_params, :response)

  end

end
