require 'assert'
require 'and-son/call_runner'

require 'sanford-protocol/fake_connection'

class AndSon::CallRunner

  class UnitTests < Assert::Context
    desc "AndSon::CallRunner"
    setup do
      @host = Factory.string
      @port = Factory.integer

      @call_runner_class = AndSon::CallRunner
    end
    subject{ @call_runner_class }

    should "include the call runner instance methods" do
      assert_includes AndSon::CallRunner::InstanceMethods, subject
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @call_runner = @call_runner_class.new(@host, @port)
    end
    subject{ @call_runner }

    should have_readers :host, :port
    should have_accessors :params_value, :timeout_value, :logger_value
    should have_imeths :call_runner

    should "know its host and port" do
      assert_equal @host, subject.host
      assert_equal @port, subject.port
    end

    should "default its params, timeout and logger" do
      assert_equal({}, subject.params_value)
      assert_equal 60, subject.timeout_value
      assert_instance_of NullLogger, subject.logger_value
    end

    should "return itself using `call_runner`" do
      assert_same subject, subject.call_runner
    end

  end

  class InitWithTimeoutEnvVarTests < UnitTests
    desc "when init with the timeout env var set"
    setup do
      @current_timeout = ENV['ANDSON_TIMEOUT']
      ENV['ANDSON_TIMEOUT'] = Factory.integer.to_s

      @call_runner = @call_runner_class.new(@host, @port)
    end
    teardown do
      ENV['ANDSON_TIMEOUT'] = @current_timeout
    end
    subject{ @call_runner }

    should "set its timeout value using the env var" do
      assert_equal ENV['ANDSON_TIMEOUT'].to_f, subject.timeout_value
    end

  end

  class InstanceMethodsTests < InitTests

    should have_imeths :timeout, :params, :logger

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

    should "stringify any values passed to `params`" do
      key = Factory.string
      value = Factory.string
      subject.params({ key.to_sym => value })
      assert_equal({ key => value }, subject.params_value)
    end

    should "raise an argument error when `params` is not passed a hash" do
      assert_raises(ArgumentError){ subject.params(Factory.string) }
    end

    should "set its logger value and return its call runner using `logger`" do
      logger_value = Factory.string
      result = subject.logger(logger_value)
      assert_equal logger_value, subject.logger_value
      assert_same subject, result
    end

  end

  class CallSetupTests < InitTests
    setup do
      @name = Factory.string
      @params = { Factory.string => Factory.string }

      @logger_spy = LoggerSpy.new
      @call_runner.logger(@logger_spy)

      @protocol_response = Sanford::Protocol::Response.new(
        [200, Factory.string],
        Factory.string
      )
      @response = AndSon::Response.new(@protocol_response)
    end

  end

  class CallTests < CallSetupTests
    desc "call method"
    setup do
      @call_bang_name = nil
      @call_bang_params = nil
      @call_bang_called = false
      Assert.stub(@call_runner, :call!) do |name, params|
        @call_bang_name = name
        @call_bang_params = params
        @call_bang_called = true
        @response
      end
    end

    should "call `call!`" do
      assert_false @call_bang_called
      subject.call(@name, @params)
      assert_equal @name, @call_bang_name
      assert_equal @params, @call_bang_params
      assert_true @call_bang_called
    end

    should "return the response data when a block isn't provided" do
      result = subject.call(@name, @params)
      assert_equal @response.data, result
    end

    should "yield the protocol response when a block is provided" do
      yielded = nil
      subject.call(@name, @params){ |response| yielded = response }
      assert_equal @protocol_response, yielded
    end

    should "default its params when they aren't provided" do
      subject.call(@name)
      assert_equal({}, @call_bang_params)
    end

    should "log a summary line of the call" do
      subject.call(@name, @params)
      assert_match /\A\[AndSon\]/, @logger_spy.output
      assert_match /time=\d+.\d+/, @logger_spy.output
      assert_match /status=#{@protocol_response.code}/, @logger_spy.output
      host_and_port = "#{@host}:#{@port}"
      assert_match /host=#{host_and_port.inspect}/, @logger_spy.output
      assert_match /service=#{@name.inspect}/, @logger_spy.output
      regex = Regexp.new(Regexp.escape("params=#{@params.inspect}"))
      assert_match regex, @logger_spy.output
    end

    should "raise an argument error when not passed a hash for params" do
      assert_raises(ArgumentError){ subject.call(@name, Factory.string) }
    end

  end

  class CallBangTests < CallSetupTests
    desc "the call! method"
    setup do
      @call_runner.params({ Factory.string => Factory.string })

      @fake_connection = FakeConnection.new
      @fake_connection.peek_data = Factory.string(1)
      @fake_connection.read_data = @protocol_response.to_hash
      Assert.stub(AndSon::Connection, :new).with(@host, @port){ @fake_connection }
    end

    should "open a connection, write a request and close the write stream" do
      subject.call!(@name, @params)

      protocol_connection = @fake_connection.protocol_connection
      params = @call_runner.params_value.merge(@params)
      expected = Sanford::Protocol::Request.new(@name, params).to_hash
      assert_equal expected, protocol_connection.write_data
      assert_true protocol_connection.closed_write
    end

    should "build a response from reading the server response on the connection" do
      response = subject.call!(@name, @params)

      protocol_connection = @fake_connection.protocol_connection
      assert_equal @call_runner.timeout_value, protocol_connection.peek_timeout
      assert_equal @call_runner.timeout_value, protocol_connection.read_timeout
      assert_equal @response, response
    end

    should "raise a connection closed error if the server doesn't write a response" do
      @fake_connection.peek_data = "" # simulate the server not writing a response
      assert_raise(AndSon::ConnectionClosedError) do
        subject.call!(@name, @params)
      end
    end

  end

  class FakeConnection
    attr_reader :protocol_connection

    def initialize
      @protocol_connection = Sanford::Protocol::FakeConnection.new
    end

    def open
      yield @protocol_connection if block_given?
    ensure
      @protocol_connection.close if @protocol_connection
    end

    def peek_data=(value)
      @protocol_connection.peek_data = value
    end

    def read_data=(value)
      @protocol_connection.read_data = value
    end
  end

  class LoggerSpy
    attr_reader :output

    def initialize
      @output = ""
    end

    def info(message)
      @output += "#{message}\n"
    end
  end

end
