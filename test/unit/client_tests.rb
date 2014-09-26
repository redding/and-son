require 'assert'
require 'and-son/client'

module AndSon::Client

  class UnitTests < Assert::Context
    desc "AndSon::Client"
    setup do
      @host = Factory.string
      @port = Factory.integer
    end
    subject{ AndSon::Client }

    should have_imeths :new

    should "return an and-son client using `new`" do
      client = subject.new(@host, @port)
      assert_instance_of AndSon::AndSonClient, client
    end

  end

  class MixinTests < UnitTests
    desc "as a mixin"
    setup do
      @client_class = Class.new do
        include AndSon::Client
      end
    end
    subject{ @client_class }

    should "include the call runner instance methods" do
      assert_includes AndSon::CallRunner::InstanceMethods, subject
    end

  end

  class InitTests < MixinTests
    desc "when init"
    setup do
      @client = @client_class.new(@host, @port)
    end
    subject{ @client }

    should have_readers :host, :port, :responses

    should "know its host and port" do
      assert_equal @host, subject.host
      assert_equal @port, subject.port
    end

    should "know its stored responses" do
      assert_instance_of AndSon::StoredResponses, subject.responses
    end

  end

  class AndSonClientTests < UnitTests
    desc "AndSonClient"
    setup do
      @client = AndSon::AndSonClient.new(@host, @port)
    end
    subject{ @client }

    should have_imeths :call, :call_runner

    should "know its call runner" do
      runner = subject.call_runner
      assert_instance_of AndSon::CallRunner, runner
      assert_equal subject.host, runner.host
      assert_equal subject.port, runner.port
      assert_equal subject.responses, runner.responses
      assert_not_same runner, subject.call_runner
    end

  end

  class AndSonClientCallTests < AndSonClientTests
    desc "call method"
    setup do
      @call_runner_spy = CallRunnerSpy.new
      Assert.stub(AndSon::CallRunner, :new){ @call_runner_spy }

      @service_name = Factory.string
      @service_params = { Factory.string => Factory.string }
      @response_block = proc{ Factory.string }

      @response = subject.call(@service_name, @service_params, &@response_block)
    end

    should "call `call` on its call runner and return its response" do
      assert_equal [@service_name, @service_params], @call_runner_spy.call_args
      assert_equal @response_block, @call_runner_spy.call_block
      assert_equal @call_runner_spy.call_response, @response
    end

  end

  class CallRunnerSpy
    attr_reader :call_args, :call_block, :call_response

    def initialize
      @call_args = []
      @call_block = nil
      @call_response = Factory.string
    end

    def call(*args, &block)
      @call_args = args
      @call_block = block
      @call_response
    end
  end

end
