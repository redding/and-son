require 'assert'

require 'sanford-protocol/test/helpers'

class MakingRequestsTest < Assert::Context
  include Sanford::Protocol::Test::Helpers

  desc "making a request that"
  setup do
    @fake_server = FakeServer.new
    @host, @port = [ '127.0.0.1', 12000 ]
    @version = 'v1'

    TCPSocket.stubs(:new).with(@host, @port).returns(@fake_server)
    IO.stubs(:select).returns([ @fake_server ])

    @client = AndSon.new(@host, @port, @version)
  end
  teardown do
    TCPSocket.unstub(:new)
    IO.unstub(:select)
  end

  class SuccessTest < MakingRequestsTest
    desc "returns a successful response"
    setup do
      @fake_server.add_service(@version, 'echo'){|params| [ 200, params ] }
      @response = @client.call('echo', 'test')
    end

    should "have gotten a 200 response with the parameter echoed back" do
      assert_equal 200,     @response.status.code
      assert_equal nil,     @response.status.message
      assert_equal 'test',  @response.data
    end
  end

  class TimeoutErrorTest < MakingRequestsTest
    desc "when a request takes to long to respond"
    setup do
      IO.stubs(:select).returns(nil) # mock IO.select behavior when it times out
    end

    should "raise a timeout error" do
      assert_raises(AndSon::TimeoutError){ @client.call('echo', 'test') }
    end
  end

end
