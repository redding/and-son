require 'assert'

class AndSon::Client

  class BaseTest < Assert::Context
    desc "AndSon::Client"
    setup do
      @host, @port = [ '0.0.0.0', 8000 ]
      @version = "v1"
      @fake_socket = FakeSocket.new(@host, @port)
      TCPSocket.stubs(:new).with(@host, @port).returns(@fake_socket)

      @client = AndSon::Client.new(@host, @port, @version)
    end
    teardown do
      TCPSocket.unstub(:new)
    end
    subject{ @client }

    should have_instance_methods :host, :port, :call
  end

  class CallTest < BaseTest
    desc "call"
    setup do
      @name, @params = [ "get_user", { :user_id => 181 } ]
      @expected_response = Sanford::Response.new(200, { :name => "Joe Test" })
      @fake_socket.add_to_read_stream(@expected_response.serialize)

      @response = @client.call(@name, @params)
    end

    should "have serialized the request and written it to the socket" do
      request = Sanford::Request.new(@name, @version, @params)

      assert_equal request.serialize, @fake_socket.write_stream.first
    end
    should "have read the serialized response off the socket and returned it" do
      assert_instance_of Sanford::Response, @response
      assert_equal @expected_response.serialize,  @response.serialize
    end
  end

  class TimeoutTest < BaseTest
    desc "that times out waiting for a response"
    setup do
      IO.stubs(:select).returns(nil) # mocking IO.select timing out
      @client = AndSon::Client.new(@host, @port, @version)
    end
    teardown do
      IO.unstub(:select)
    end

    should "raise a AndSon::TimeoutError" do
      assert_raises(AndSon::TimeoutError) do
        @client.call("anything", {})
      end
    end
  end

  class BadMessageTest < BaseTest
    desc "with a bad response message"
    setup do
      @fake_socket.add_to_read_stream("H")
    end

    should "raise a Sanford::BadResponseError" do
      exception = nil
      begin; @client.call("anything", {}); rescue Exception => exception; end

      assert_instance_of AndSon::BadResponseError, exception
      assert_match "size", exception.message
    end
  end

  class WrongProtocolVersionTest < BaseTest
    desc "with a bad protocol version"
    setup do
      response = Sanford::Response.new(200, { :name => "Joe Test" })
      serialized = response.serialize
      serialized[4] = [ 145 ].pack('C')
      @fake_socket.add_to_read_stream(serialized)
    end

    should "raise a Sanford::BadResponseError" do
      exception = nil
      begin; @client.call("anything", {}); rescue Exception => exception; end

      assert_instance_of AndSon::BadResponseError, exception
      assert_match "protocol version", exception.message
    end
  end

  class BadBodyTest < BaseTest
    desc "with a bad message body"
    setup do
      response = Sanford::Response.new(200, { :name => "Joe Test" })
      serialized = response.serialize
      serialized[5..-1] = "notbsonkid"
      @fake_socket.add_to_read_stream(serialized)
    end

    should "raise a Sanford::BadResponseError" do
      exception = nil
      begin; @client.call("anything", {}); rescue Exception => exception; end

      assert_instance_of AndSon::BadResponseError, exception
      assert_match "body", exception.message
    end
  end

end
