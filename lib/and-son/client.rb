require 'and-son/call_runner'
require 'and-son/stored_responses'

module AndSon

  module Client

    def self.new(host, port)
      AndSonClient.new(host, port)
    end

    def self.included(klass)
      klass.class_eval do
        include CallRunner::InstanceMethods
        include InstanceMethods
      end
    end

    module InstanceMethods

      attr_reader :host, :port, :responses

      def initialize(host, port)
        @host, @port = host, port
        @responses = AndSon::StoredResponses.new
      end

    end

  end

  class AndSonClient
    include Client

    # proxy the call method to the call runner
    def call(*args, &block); self.call_runner.call(*args, &block); end

    def call_runner
      AndSon::CallRunner.new(host, port, @responses)
    end

  end

end
