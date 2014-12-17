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
    should have_readers :before_call_procs, :after_call_procs
    should have_accessors :params_value, :timeout_value, :logger_value
    should have_imeths :call_runner

    should "know its host and port" do
      assert_equal @host, subject.host
      assert_equal @port, subject.port
    end

    should "default its params, timeout, logger and callbacks" do
      assert_equal({}, subject.params_value)
      assert_equal 60, subject.timeout_value
      assert_instance_of NullLogger, subject.logger_value
      assert_equal [], subject.before_call_procs
      assert_equal [], subject.after_call_procs
    end

    should "return itself using `call_runner`" do
      assert_same subject, subject.call_runner
    end

    should "be comparable" do
      matching = @call_runner_class.new(@host, @port)
      assert_equal matching, subject

      not_matching = @call_runner_class.new(Factory.string, @port)
      assert_not_equal not_matching, subject
      not_matching = @call_runner_class.new(@host, Factory.integer)
      assert_not_equal not_matching, subject
      params = { Factory.string => Factory.string }
      not_matching = @call_runner_class.new(@host, @port).params(params)
      assert_not_equal not_matching, subject
      not_matching = @call_runner_class.new(@host, @port).logger(Factory.string)
      assert_not_equal not_matching, subject
      not_matching = @call_runner_class.new(@host, @port).timeout(Factory.integer)
      assert_not_equal not_matching, subject
    end

    should "be hash comparable" do
      assert_equal subject.call_runner.hash, subject.hash

      matching = @call_runner_class.new(@host, @port)
      assert_true subject.eql?(matching)
      not_matching = @call_runner_class.new(Factory.string, Factory.integer)
      assert_false subject.eql?(not_matching)
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
    should have_imeths :before_call, :after_call

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

    should "add a before call proc using `before_call`" do
      callback = proc{ Factory.string }
      result = subject.before_call(&callback)
      assert_equal [callback], subject.before_call_procs

      other_callback = proc{ Factory.string }
      result = subject.before_call(&other_callback)
      assert_equal 2, subject.before_call_procs.size
      assert_equal other_callback, subject.before_call_procs.last
    end

    should "add an after call proc using `after_call`" do
      callback = proc{ Factory.string }
      result = subject.after_call(&callback)
      assert_equal [callback], subject.after_call_procs

      other_callback = proc{ Factory.string }
      result = subject.after_call(&other_callback)
      assert_equal 2, subject.after_call_procs.size
      assert_equal other_callback, subject.after_call_procs.last
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
      @fake_connection = FakeConnection.new
      @fake_connection.peek_data = Factory.string(1)
      @fake_connection.read_data = @protocol_response.to_hash
      Assert.stub(AndSon::Connection, :new).with(@host, @port){ @fake_connection }
    end

    should "open a connection, write a request and close the write stream" do
      subject.call(@name, @params)

      protocol_connection = @fake_connection.protocol_connection
      exp = Sanford::Protocol::Request.new(@name, @params).to_hash
      assert_equal exp, protocol_connection.write_data
      assert_true protocol_connection.closed_write
    end

    should "build a response from reading the server response on the connection" do
      response_data = subject.call(@name, @params)

      protocol_connection = @fake_connection.protocol_connection
      assert_equal @call_runner.timeout_value, protocol_connection.peek_timeout
      assert_equal @call_runner.timeout_value, protocol_connection.read_timeout
      assert_equal @response.data, response_data
    end

    should "raise a connection closed error if the server doesn't write a response" do
      @fake_connection.peek_data = "" # simulate the server not writing a response
      assert_raise(AndSon::ConnectionClosedError) do
        subject.call(@name, @params)
      end
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

      protocol_connection = @fake_connection.protocol_connection
      exp = Sanford::Protocol::Request.new(@name, {}).to_hash
      assert_equal exp, protocol_connection.write_data
    end

    should "merge the passed params with its params value" do
      subject.params({ Factory.string => Factory.string })
      merged_params = subject.params_value.merge(@params)
      subject.call(@name, @params)

      protocol_connection = @fake_connection.protocol_connection
      exp = Sanford::Protocol::Request.new(@name, merged_params).to_hash
      assert_equal exp, protocol_connection.write_data
    end

    should "run before call procs" do
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
      assert_equal @params, yielded_params
      assert_same subject, yielded_runner
    end

    should "run after call procs" do
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
      assert_equal @params, yielded_params
      assert_same subject, yielded_runner
    end

    should "run callbacks in the correct order" do
      n = 0
      before_call_num = nil
      after_call_num  = nil
      call_num        = nil
      subject.before_call{ before_call_num = n += 1 }
      subject.after_call{ after_call_num = n += 1 }
      # the connection should be created between the callbacks
      Assert.stub(AndSon::Connection, :new).with(@host, @port) do
        call_num = n += 1
        @fake_connection
      end

      subject.call(@name, @params)
      assert_equal 1, before_call_num
      assert_equal 2, call_num
      assert_equal 3, after_call_num
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
