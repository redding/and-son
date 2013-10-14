require 'assert'
require 'test/support/fake_connection'
require 'test/support/fake_server'
require 'and-son/stored_responses'
require 'and-son/client'

class AndSon::Client

  class BaseTests < Assert::Context
    include FakeServer::Helper

    desc "AndSon::Client"
    setup do
      @host, @port = '0.0.0.0', 8000
      @client = AndSon::Client.new(@host, @port)
    end
    subject{ @client }

    should have_imeths :host, :port, :responses
    should have_imeths :call_runner, :call, :timeout, :logger, :params

    should "know its default call runner" do
      default_runner = subject.call_runner

      assert_equal @host, default_runner.host
      assert_equal @port, default_runner.port
      assert_equal 60.0, default_runner.timeout_value
      assert_instance_of AndSon::NullLogger, default_runner.logger_value
    end

    should "override the default call runner timeout with an env var" do
      prev = ENV['ANDSON_TIMEOUT']
      ENV['ANDSON_TIMEOUT'] = '20'

      assert_equal 20.0, subject.call_runner.timeout_value

      ENV['ANDSON_TIMEOUT'] = prev
    end

    should "return a CallRunner with a timeout value set #timeout" do
      runner = subject.timeout(10)

      assert_kind_of AndSon::CallRunner, runner
      assert_respond_to :call, runner
      assert_equal 10.0, runner.timeout_value
    end

    should "return a CallRunner with params_value set using #params and stringify " \
           "the params hash" do
      runner = subject.params({ :api_key => 12345 })

      assert_kind_of AndSon::CallRunner, runner
      assert_respond_to :call, runner
      assert_equal({ "api_key" => 12345 }, runner.params_value)
    end

    should "return a CallRunner with a logger value set #logger" do
      runner = subject.logger(logger = Logger.new(STDOUT))

      assert_kind_of AndSon::CallRunner, runner
      assert_respond_to :call, runner
      assert_equal logger, runner.logger_value
    end

    should "raise an ArgumentError when #params is not passed a Hash" do
      assert_raises(ArgumentError) do
        subject.params('test')
      end
    end
    should "track its stored responses" do
      assert_kind_of AndSon::StoredResponses, subject.responses
    end

  end

  class CallTest < BaseTests
    desc "call"
    setup do
      @connection = AndSon::Connection.new('localhost', 12001)
      @response = AndSon::Response.parse({ 'status' => [200] })
      @fake_connection = FakeConnection.new
      AndSon::Connection.stubs(:new).returns(@connection)
    end
    teardown do
      AndSon::Connection.unstub(:new)
    end

    should "write a request to the connection" do
      @connection.stubs(:open).yields(@fake_connection).returns(@response)

      client = AndSon::Client.new('localhost', 12001).call('echo', {
        :message => 'test'
      })

      request_data = @fake_connection.written.first
      assert_equal 'echo',                  request_data['name']
      assert_equal({ 'message' => 'test' }, request_data['params'])
    end

    should "close the write stream" do
      @connection.stubs(:open).yields(@fake_connection).returns(@response)

      client = AndSon::Client.new('localhost', 12001).call('echo', {
        :message => 'test'
      })

      assert @fake_connection.write_stream_closed?
    end

    should "raise an ArgumentError when #call is not passed a Hash for params" do
      client = AndSon::Client.new('localhost', 12001)
      runner = client.timeout(0.1) # in case it actually tries to make the request

      assert_raises(ArgumentError) do
        runner.call('something', 'test')
      end
    end

    should "raise a ConnectionClosedError when the server closes the connection" do
      self.start_closing_server(12001) do
        client = AndSon::Client.new('localhost', 12001)

        assert_raises(AndSon::ConnectionClosedError) do
          client.call('anything')
        end
      end
    end

  end

end
