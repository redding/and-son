require 'assert'
require 'and-son/stored_responses'

class AndSon::StoredResponses

  class UnitTests < Assert::Context
    desc "AndSon::StoredResponses"
    setup do
      @name = Factory.string
      @params = { Factory.string => Factory.string }
      @response_data = Factory.string

      @responses = AndSon::StoredResponses.new
    end
    subject{ @responses }

    should have_imeths :add, :get, :remove, :remove_all

    should "allow adding and getting responses with response data" do
      subject.add(@name){ @response_data }
      protocol_response = subject.get(@name, {}).protocol_response

      assert_equal 200, protocol_response.code
      assert_nil protocol_response.status.message
      assert_equal @response_data, protocol_response.data
    end

    should "allow adding and getting responses when yielded a response" do
      code    = Factory.integer
      message = Factory.string
      data    = Factory.string

      yielded = nil
      subject.add(@name) do |response|
        yielded = response
        response.code    = code
        response.message = message
        response.data    = data
      end
      protocol_response = subject.get(@name, {}).protocol_response

      assert_instance_of Sanford::Protocol::Response, yielded
      assert_equal code,    protocol_response.code
      assert_equal message, protocol_response.message
      assert_equal data,    protocol_response.data
    end

    should "return a stub when adding a response" do
      stub = subject.add(@name)
      assert_instance_of AndSon::StoredResponses::Stub, stub

      stub.with(@params){ @response_data }
      response = subject.get(@name, @params)
      assert_equal @response_data, response.data

      response = subject.get(@name, {})
      assert_not_equal @response_data, response.data
    end

    should "return a default response for a service that isn't configured" do
      response = subject.get(@name, {})
      protocol_response = response.protocol_response

      assert_equal 200, protocol_response.code
      assert_nil protocol_response.status.message
      assert_equal({}, protocol_response.data)
    end

    should "not call a response block until it is retrieved" do
      called = false
      subject.add(@name){ called = true }
      assert_false called
      subject.get(@name, {})
      assert_true called
    end

    should "allow removing a stub" do
      subject.add(@name){ @response_data }
      protocol_response = subject.get(@name, {}).protocol_response
      assert_equal @response_data, protocol_response.data

      subject.remove(@name)
      protocol_response = subject.get(@name, {}).protocol_response
      assert_not_equal @response_data, protocol_response.data
    end

    should "allow removing all responses" do
      subject.add(@name){ @response_data }
      other_name = Factory.string
      subject.add(other_name){ @response_data }

      subject.remove_all
      protocol_response = subject.get(@name, {}).protocol_response
      assert_not_equal @response_data, protocol_response.data
      protocol_response = subject.get(other_name, {}).protocol_response
      assert_not_equal @response_data, protocol_response.data
    end

  end

  class StubTests < UnitTests
    desc "Stub"
    setup do
      @stub = Stub.new
    end
    subject{ @stub }

    should have_readers :hash
    should have_imeths :set_default_proc, :with, :call

    should "default its default response proc" do
      response = subject.call(@params)
      assert_equal({}, response.data)
    end

    should "allow settings its default proc" do
      data = Factory.string
      subject.set_default_proc{ |r| r.data = data }
      response = subject.call(@params)
      assert_equal data, response.data
    end

    should "allow setting responses for specific params" do
      response = subject.call(@params)
      assert_equal({}, response.data)

      data = Factory.string
      subject.with(@params){ |r| r.data = data }
      response = subject.call(@params)
      assert_equal data, response.data
    end

    should "yield a response when a response block expects an arg" do
      yielded = nil
      subject.with(@params){ |r| yielded = r }
      exp = Sanford::Protocol::Response.new(200, {})
      assert_equal exp, subject.call(@params)
      assert_equal exp, yielded
    end

    should "set a response data when the response block doesn't expect an arg" do
      data = Factory.string
      subject.with(@params){ data  }
      exp = Sanford::Protocol::Response.new(200, data)
      assert_equal exp, subject.call(@params)
    end

  end

end
