require 'assert'

class AndSon::Client

  class BaseTest < Assert::Context
    desc "AndSon::Client"
    setup do
      @host, @port = [ '0.0.0.0', 8000 ]
      @version = "v1"
      @client = AndSon::Client.new(@host, @port, @version)
    end
    subject{ @client }

    should have_instance_methods :host, :port, :version, :timeout, :call

    should "default it's timeout to AndSon's timeout" do
      assert_equal AndSon.config.listen_timeout, subject.timeout
    end
  end

  # the `call` method is tested in the file test/system/making_requests_test.rb,
  # because there is a lot of setup needed to call this method

end
