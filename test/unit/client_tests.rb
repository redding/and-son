require 'assert'
require 'and-son/client'

module AndSon::Client

  class UnitTests < Assert::Context
    desc "AndSon::Client"
    setup do
      @current_test_mode = ENV['ANDSON_TEST_MODE']
      ENV['ANDSON_TEST_MODE'] = 'yes'

      @host = Factory.string
      @port = Factory.integer
    end
    teardown do
      ENV['ANDSON_TEST_MODE'] = @current_test_mode
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

    should "be comparable" do
      matching = AndSon::AndSonClient.new(@host, @port)
      assert_equal matching, subject

      not_matching = AndSon::AndSonClient.new(Factory.string, Factory.integer)
      assert_not_equal not_matching, subject
    end

    should "be hash comparable" do
      assert_equal subject.call_runner.hash, subject.hash

      matching = AndSon::AndSonClient.new(@host, @port)
      assert_true subject.eql?(matching)
      not_matching = AndSon::AndSonClient.new(Factory.string, Factory.integer)
      assert_false subject.eql?(not_matching)
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

      Assert.stub(Sanford::Protocol.msg_body, :encode){ |r| @encoded_request = r }

      @client = AndSon::TestClient.new(@host, @port)
    end
    subject{ @client }

    should have_readers :calls, :responses
    should have_readers :before_call_procs, :after_call_procs
    should have_accessors :timeout_value, :params_value, :logger_value
    should have_imeths :add_response, :remove_responses, :reset

    should "know its calls and stored responses" do
      assert_equal [], subject.calls
      assert_instance_of AndSon::StoredResponses, subject.responses
    end

    should "default its params and callbacks" do
      assert_equal({}, subject.params_value)
      assert_equal [], subject.before_call_procs
      assert_equal [], subject.after_call_procs
    end

    should "know its call runner" do
      assert_equal subject, subject.call_runner
    end

    should "store each call made in its `calls`" do
      assert_equal [], subject.calls
      subject.call(@name, @params)
      assert_equal 1, subject.calls.size

      call = subject.calls.last
      assert_instance_of AndSon::TestClient::Call, call
      assert_equal @name, call.request_name
      assert_equal @params, call.request_params
      assert_instance_of Sanford::Protocol::Response, call.response
    end

    should "return a stored response's data using `call`" do
      exp = subject.responses.get(@name, @params)
      assert_equal exp.data, subject.call(@name, @params)
    end

    should "yield a stored response using `call` with a block" do
      yielded = nil
      subject.call(@name, @params){ |response| yielded = response }
      exp = subject.responses.get(@name, @params)
      assert_equal exp.protocol_response, yielded
    end

    should "build and encode a request when called" do
      subject.call(@name, @params)
      exp = Sanford::Protocol::Request.new(@name, @params).to_hash
      assert_equal exp, @encoded_request
    end

    should "run before call procs" do
      subject.params({ Factory.string => Factory.string })
      yielded_name    = nil
      yielded_params  = nil
      yielded_runner  = nil
      subject.before_call do |name, params, call_runner|
        yielded_name   = name
        yielded_params = params
        yielded_runner = call_runner
      end

      subject.call(@name, @params)
      assert_equal @name,   yielded_name
      exp = subject.params_value.merge(@params)
      assert_equal exp, yielded_params
      assert_same subject, yielded_runner
    end

    should "run after call procs" do
      subject.params({ Factory.string => Factory.string })
      yielded_name    = nil
      yielded_params  = nil
      yielded_runner  = nil
      subject.after_call do |name, params, call_runner|
        yielded_name   = name
        yielded_params = params
        yielded_runner = call_runner
      end

      subject.call(@name, @params)
      assert_equal @name,   yielded_name
      exp = subject.params_value.merge(@params)
      assert_equal exp, yielded_params
      assert_same subject, yielded_runner
    end

    should "run callbacks in the correct order" do
      n = 0
      before_call_num = nil
      after_call_num  = nil
      subject.before_call{ before_call_num = n += 1 }
      subject.after_call{ after_call_num = n += 1 }

      subject.call(@name, @params)
      assert_equal 1, before_call_num
      assert_equal 2, after_call_num
    end

    should "allow adding/removing stored responses" do
      data = Factory.string
      subject.add_response(@name).with(@params){ data }
      response = subject.responses.get(@name, @params)
      assert_equal data, response.data

      subject.remove_responses(@name)
      response = subject.responses.get(@name, @params)
      assert_not_equal data, response.data
    end

    should "return a stored response stub using `add_response`" do
      stub = subject.add_response(@name)
      assert_instance_of AndSon::StoredResponses::Stub, stub

      data = Factory.string
      stub.with(@params){ data }
      response = subject.responses.get(@name, @params)
      assert_equal data, response.data

      response = subject.responses.get(@name, {
        Factory.string => Factory.string
      })
      assert_not_equal data, response.data
    end

    should "clear its calls and remove all its configured responses using `reset`" do
      subject.call(@name, @params)
      data = Factory.string
      subject.add_response(@name).with(@params){ data }

      assert_not_empty subject.calls
      assert_equal data, subject.responses.get(@name, @params).data

      subject.reset
      assert_empty subject.calls
      assert_not_equal data, subject.responses.get(@name, @params).data
    end

    should "be comparable" do
      matching = AndSon::TestClient.new(@host, @port)
      assert_equal matching, subject

      not_matching = AndSon::TestClient.new(Factory.string, @port)
      assert_not_equal not_matching, subject
      not_matching = AndSon::TestClient.new(@host, Factory.integer)
      assert_not_equal not_matching, subject
      params = { Factory.string => Factory.string }
      not_matching = AndSon::TestClient.new(@host, @port).params(params)
      assert_not_equal not_matching, subject
      not_matching = AndSon::TestClient.new(@host, @port).logger(Factory.string)
      assert_not_equal not_matching, subject
      not_matching = AndSon::TestClient.new(@host, @port).timeout(Factory.integer)
      assert_not_equal not_matching, subject
    end

    should "be hash comparable" do
      assert_equal subject.call_runner.hash, subject.hash

      matching = AndSon::TestClient.new(@host, @port)
      assert_true subject.eql?(matching)
      not_matching = AndSon::TestClient.new(Factory.string, Factory.integer)
      assert_false subject.eql?(not_matching)
    end

  end

  class TestClientInstanceMethodsTests < TestClientTests

    should "set its timeout value and return its call runner using `timeout`" do
      timeout_value = Factory.integer
      result = subject.timeout(timeout_value)
      assert_equal timeout_value, subject.timeout_value
      assert_same subject, result
    end

    should "update its params value and return its call runner using `params`" do
      params_value = { Factory.string => Factory.string }
      result = subject.params(params_value)
      assert_equal params_value, subject.params_value
      assert_same subject, result

      new_key = Factory.string
      new_value = Factory.string
      subject.params({ new_key => new_value })
      assert_equal 2, subject.params_value.keys.size
      assert_equal new_value, subject.params_value[new_key]
    end

    should "set its logger value and return its call runner using `logger`" do
      logger_value = Factory.string
      result = subject.logger(logger_value)
      assert_equal logger_value, subject.logger_value
      assert_same subject, result
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
