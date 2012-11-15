require 'assert'

class AndSon::Client

  class BaseTest < Assert::Context
    desc "AndSon::Client"
    setup do
      @host, @port, @version = '0.0.0.0', 8000, "v1"
      @client = AndSon::Client.new(@host, @port, @version)
    end
    subject{ @client }

    should have_imeths :host, :port, :version
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
  end

  # the `call` method is tested in the file test/system/making_requests_test.rb,
  # because there is a lot of setup needed to call this method

end
