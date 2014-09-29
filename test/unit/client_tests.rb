require 'assert'
require 'and-son/client'

module AndSon::Client

  class UnitTests < Assert::Context
    desc "AndSon::Client"
    setup do
      @current_timeout = ENV['ANDSON_TEST_MODE']
      ENV['ANDSON_TEST_MODE'] = 'yes'

      @host = Factory.string
      @port = Factory.integer
    end
    teardown do
      ENV['ANDSON_TEST_MODE'] = @current_timeout
    end
    subject{ AndSon::Client }

    should have_imeths :new

    should "return an and-son client using `new`" do
      ENV.delete('ANDSON_TEST_MODE')
      client = subject.new(@host, @port)
      assert_instance_of AndSon::AndSonClient, client
    end

    should "return a test client using `new` in test mode" do
      client = subject.new(@host, @port)
      assert_instance_of AndSon::TestClient, client
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

    should have_readers :host, :port

    should "know its host and port" do
      assert_equal @host, subject.host
      assert_equal @port, subject.port
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

  class TestClientTests < UnitTests
    desc "TestClient"
    setup do
      @name = Factory.string
      @params = { Factory.string => Factory.string }

      @client = AndSon::TestClient.new(@host, @port)
      data = Factory.string
      @client.add_response(@name, @params){ data }
      @response = @client.responses.get(@name, @params)
    end
    subject{ @client }

    should have_readers :calls, :responses
    should have_imeths :add_response, :remove_response, :reset

    should "know its stored responses" do
      assert_instance_of AndSon::StoredResponses, subject.responses
    end

    should "know its call runner" do
      subject
    end

    should "store each call made in its `calls`" do
      assert_equal [], subject.calls
      subject.call(@name, @params)
      assert_equal 1, subject.calls.size

      call = subject.calls.last
      assert_instance_of AndSon::TestClient::Call, call
      assert_equal @name, call.request_name
      assert_equal @params, call.request_params
      assert_equal @response.protocol_response, call.response
    end

    should "return a stored response using `call`" do
      assert_equal @response.data, subject.call(@name, @params)
    end

    should "yield a stored response using `call` with a block" do
      yielded = nil
      subject.call(@name, @params){ |response| yielded = response }
      assert_equal @response.protocol_response, yielded
    end

    should "allow adding/removing stored responses" do
      data = Factory.string
      subject.add_response(@name, @params){ data }
      response = subject.responses.get(@name, @params)
      assert_equal data, response.data

      subject.remove_response(@name, @params)
      response = subject.responses.get(@name, @params)
      assert_not_equal data, response.data
    end

    should "clear its calls and remove all its configured responses using `reset`" do
      subject.call(@name, @params)
      assert_not_equal [], subject.calls
      assert_equal @response, subject.responses.get(@name, @params)

      subject.reset
      assert_equal [], subject.calls
      assert_not_equal @response, subject.responses.get(@name, @params)
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
