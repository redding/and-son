require 'assert'
require 'and-son'

require 'test/support/fake_server'

class MakingRequestsTests < Assert::Context
  include FakeServer::Helper

  desc "making a request that"
  setup do
    @fake_server = FakeServer.new(12000)
  end

  class SuccessTests < MakingRequestsTests
    desc "returns a successful response"
    setup do
      @fake_server.add_handler('echo'){|params| [ 200, params['message'] ] }
    end

    should "get a 200 response with the parameter echoed back" do
      self.run_fake_server(@fake_server) do

        client = AndSon.new('localhost', 12000)
        client.call('echo', :message => 'test') do |response|
          assert_equal 200,     response.status.code
          assert_equal nil,     response.status.message
          assert_equal 'test',  response.data
        end

      end
    end

  end

  class WithStoredResponsesTests < MakingRequestsTests
    desc "is stored with and-son and with testing ENV var set"
    setup do
      ENV['ANDSON_TEST_MODE'] = 'yes'
    end
    teardown do
      ENV.delete('ANDSON_TEST_MODE')
    end

    should "return the registered response" do
      client = AndSon.new('localhost', 12000)
      client.add_response('echo', 'message' => 'test'){ 'test' }

      client.call('echo', 'message' => 'test') do |response|
        assert_equal 200,     response.code
        assert_equal nil,     response.status.message
        assert_equal 'test',  response.data
      end
    end

  end

  class AuthorizeTests < MakingRequestsTests
    setup do
      @fake_server.add_handler('authorize_it') do |params|
        if params['api_key'] == 12345
          [ 200, params['data'] ]
        else
          [ 401, params['data'] ]
        end
      end
    end

    should "get a 200 response when api_key is passed with the correct value" do
      self.run_fake_server(@fake_server) do

        client = AndSon.new('localhost', 12000).params({ 'api_key' => 12345 })
        client.call('authorize_it', { 'data' => 'holla' }) do |response|
          assert_equal 200,     response.status.code
          assert_equal nil,     response.status.message
          assert_equal 'holla', response.data
        end

      end
    end

    should "get a 401 response when api_key isn't passed" do
      self.run_fake_server(@fake_server) do

        client = AndSon.new('localhost', 12000)
        client.call('authorize_it', { 'data' => 'holla' }) do |response|
          assert_equal 401,     response.status.code
          assert_equal nil,     response.status.message
          assert_equal 'holla', response.data
        end

      end
    end

  end

  class Failure400Tests < MakingRequestsTests
    desc "when a request fails with a 400"
    setup do
      @fake_server.add_handler('400'){|params| [ 400, false ] }
    end

    should "raise a bad request error" do
      self.run_fake_server(@fake_server) do

        assert_raises(AndSon::BadRequestError) do
          client = AndSon.new('localhost', 12000)
          client.call('400')
        end

      end
    end

  end

  class Failure404Tests < MakingRequestsTests
    desc "when a request fails with a 404"
    setup do
      @fake_server.add_handler('404'){|params| [ 404, false ] }
    end

    should "raise a not found error" do
      self.run_fake_server(@fake_server) do

        assert_raises(AndSon::NotFoundError) do
          client = AndSon.new('localhost', 12000)
          client.call('404')
        end

      end
    end

  end

  class Failure4xxTests < MakingRequestsTests
    desc "when a request fails with a 4xx"
    setup do
      @fake_server.add_handler('4xx'){|params| [ 402, false ] }
    end

    should "raise a client error" do
      self.run_fake_server(@fake_server) do

        assert_raises(AndSon::ClientError) do
          client = AndSon.new('localhost', 12000)
          client.call('4xx')
        end

      end
    end

  end

  class Failure5xxTests < MakingRequestsTests
    desc "when a request fails with a 5xx"
    setup do
      @fake_server.add_handler('5xx'){|params| [ 500, false ] }
    end

    should "raise a server error" do
      self.run_fake_server(@fake_server) do

        assert_raises(AndSon::ServerError) do
          client = AndSon.new('localhost', 12000)
          client.call('5xx')
        end

      end
    end

  end

  class TimeoutErrorTests < MakingRequestsTests
    desc "when a request takes to long to respond"
    setup do
      @fake_server.add_handler('forever') do |params|
        sleep 0.2
        [ 200, true ]
      end
    end

    should "raise a timeout error" do
      self.run_fake_server(@fake_server) do

        assert_raises(Sanford::Protocol::TimeoutError) do
          client = AndSon.new('localhost', 12000)
          client.timeout(0.1).call('forever')
        end

      end
    end

  end

end
