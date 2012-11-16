require 'assert'

class MakingRequestsTest < Assert::Context
  include FakeServer::Helper

  desc "making a request that"
  setup do
    @fake_server = FakeServer.new(12000)
  end

  class SuccessTest < MakingRequestsTest
    desc "returns a successful response"
    setup do
      @fake_server.add_handler('v1', 'echo'){|params| [ 200, params ] }
    end

    should "have gotten a 200 response with the parameter echoed back" do
      self.run_fake_server(@fake_server) do

        client = AndSon.new('localhost', 12000, 'v1')
        client.call('echo', 'test') do |response|
          assert_equal 200,     response.status.code
          assert_equal nil,     response.status.message
          assert_equal 'test',  response.data
        end

      end
    end

  end

  class TimeoutErrorTest < MakingRequestsTest
    desc "when a request takes to long to respond"
    setup do
      @fake_server.add_handler('v1', 'forever') do |params|
        sleep 0.2
        [ 200, true ]
      end
    end

    should "raise a timeout error" do
      self.run_fake_server(@fake_server) do

        assert_raises(Sanford::Protocol::TimeoutError) do
          client = AndSon.new('localhost', 12000, 'v1')
          client.timeout(0.1).call('forever')
        end

      end
    end
  end

end
