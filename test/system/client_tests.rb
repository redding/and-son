require 'assert'
require 'and-son/client'

require 'test/support/test_server'

module AndSon::Client

  class SystemTests < Assert::Context
    desc "AndSon::Client"
    setup do
      @host = '127.0.0.1'
      @port = 12000
    end

  end

  class UsingTestServerSetupTests < SystemTests
    include TestServer::TestHelpers

    setup do
      @test_server = TestServer.new(@port)
    end

  end

  class SuccessfulRequestTests < UsingTestServerSetupTests
    desc "when making a request to a service"
    setup do
      @service_name = Factory.string
      @test_server.add_handler(@service_name) do |params|
        [200, params['message']]
      end
      @client = AndSon.new(@host, @port)
    end

    should "return a 200 response" do
      self.run_test_server(@test_server) do

        params = { 'message' => Factory.string }
        @client.call(@service_name, params) do |r|
          assert_equal 200, r.code
          assert_equal params['message'], r.data
          assert_nil r.message
        end

      end
    end

  end

  class BadRequestTests < UsingTestServerSetupTests
    desc "when making a request to a service that returns a 400"
    setup do
      @service_name = Factory.string
      @test_server.add_handler(@service_name) do |params|
        [400, Factory.string]
      end
      @client = AndSon.new(@host, @port)
    end

    should "raise a bad request error" do
      self.run_test_server(@test_server) do

        assert_raises(AndSon::BadRequestError) do
          @client.call(@service_name)
        end

      end
    end

  end

  class NotFoundRequestTests < UsingTestServerSetupTests
    desc "when making a request to a service that returns a 404"
    setup do
      @service_name = Factory.string
      @test_server.add_handler(@service_name) do |params|
        [404, Factory.string]
      end
      @client = AndSon.new(@host, @port)
    end

    should "raise a not found error" do
      self.run_test_server(@test_server) do

        assert_raises(AndSon::NotFoundError) do
          @client.call(@service_name)
        end

      end
    end

  end

  class ClientErrorRequestTests < UsingTestServerSetupTests
    desc "when making a request to a service that returns a 4XX"
    setup do
      @service_name = Factory.string
      @test_server.add_handler(@service_name) do |params|
        code = Factory.integer(99) + 400
        [code, Factory.string]
      end
      @client = AndSon.new(@host, @port)
    end

    should "raise a client error" do
      self.run_test_server(@test_server) do

        assert_raises(AndSon::ClientError) do
          @client.call(@service_name)
        end

      end
    end

  end

  class ServerErrorRequestTests < UsingTestServerSetupTests
    desc "when making a request to a service that returns a 4XX"
    setup do
      @service_name = Factory.string
      @test_server.add_handler(@service_name) do |params|
        code = Factory.integer(99) + 500
        [code, Factory.string]
      end
      @client = AndSon.new(@host, @port)
    end

    should "raise a server error" do
      self.run_test_server(@test_server) do

        assert_raises(AndSon::ServerError) do
          @client.call(@service_name)
        end

      end
    end

  end

  class TimeoutRequestTests < UsingTestServerSetupTests
    desc "when making a request to a service that takes to long to respond"
    setup do
      @service_name = Factory.string
      @test_server.add_handler(@service_name) do |params|
        sleep 0.2
        [200, Factory.string]
      end
      @client = AndSon.new(@host, @port).timeout(0.1)
    end

    should "raise a timeout error" do
      self.run_test_server(@test_server) do

        assert_raises(Sanford::Protocol::TimeoutError) do
          @client.call(@service_name)
        end

      end
    end

  end

  class StoredResponseTests < SystemTests
    desc "with stored responses"
    setup do
      ENV['ANDSON_TEST_MODE'] = 'yes'

      @client = AndSon.new(@host, @port)

      @service_name   = Factory.string
      @service_params = { Factory.string => Factory.string }
      @response_data  = Factory.string
      @client.add_response(@service_name, @service_params){ @response_data }
    end
    teardown do
      ENV.delete('ANDSON_TEST_MODE')
    end

    should "return the configured response when the name and params match" do
      @client.call(@service_name, @service_params) do |r|
        assert_equal 200, r.code
        assert_equal @response_data, r.data
        assert_nil r.message
      end
    end

  end

end
