require 'assert'
require 'and-son/stored_responses'

class AndSon::Client

  class BaseTest < Assert::Context
    desc "AndSon::Client"
    setup do
      @host, @port, @version = '0.0.0.0', 8000, "v1"
      @client = AndSon::Client.new(@host, @port, @version)
    end
    subject{ @client }

    should have_readers :host, :port, :version, :responses
    should have_imeths :call_runner, :call, :timeout

    should "know its default call runner" do
      default_runner = subject.call_runner

      assert_equal @host, default_runner.host
      assert_equal @port, default_runner.port
      assert_equal @version, default_runner.version
      assert_equal 60.0, default_runner.timeout_value
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

    should "raise an ArgumentError when #params is not passed a Hash" do
      assert_raises(ArgumentError) do
        subject.params('test')
      end
    end

    should "raise an ArgumentError when #call is not passed a Hash for params" do
      runner = subject.timeout(0.1) # in case it actually tries to make the request

      assert_raises(ArgumentError) do
        runner.call('something', 'test')
      end
    end

    should "track its stored responses" do
      assert_kind_of AndSon::StoredResponses, subject.responses
    end

  end

  # the `call` method is tested in the file test/system/making_requests_test.rb,
  # because there is a lot of setup needed to call this method

end
