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
      subject.add(@name, @params){ @response_data }
      protocol_response = subject.get(@name, @params).protocol_response
      assert_equal 200, protocol_response.code
      assert_nil protocol_response.status.message
      assert_equal @response_data, protocol_response.data
    end

    should "allow adding and gettings responses being yielded a response" do
      code = Factory.integer
      message = Factory.string
      data = Factory.string

      yielded = nil
      subject.add(@name, @params) do |response|
        yielded = response
        response.code = code
        response.message = message
        response.data = data
      end
      protocol_response = subject.get(@name, @params).protocol_response

      assert_instance_of Sanford::Protocol::Response, yielded
      assert_equal code, protocol_response.code
      assert_equal message, protocol_response.message
      assert_equal data, protocol_response.data
    end

    should "allow adding and getting responses with no params" do
      subject.add(@name){ @response_data }
      protocol_response = subject.get(@name).protocol_response
      assert_equal @response_data, protocol_response.data
    end

    should "return a default response for a name/params that isn't configured" do
      response = subject.get(@name, @params)
      protocol_response = response.protocol_response
      assert_equal 200, protocol_response.code
      assert_nil protocol_response.status.message
      assert_equal({}, protocol_response.data)
    end

    should "not call a response block until it is retrieved" do
      called = false
      subject.add(@name){ called = true }
      assert_false called
      subject.get(@name)
      assert_true called
    end

    should "allow removing a response" do
      subject.add(@name, @params){ @response_data }
      protocol_response = subject.get(@name, @params).protocol_response
      assert_equal @response_data, protocol_response.data

      subject.remove(@name, @params)
      protocol_response = subject.get(@name, @params).protocol_response
      assert_not_equal @response_data, protocol_response.data
    end

    should "allow removing a response without params" do
      subject.add(@name){ @response_data }
      protocol_response = subject.get(@name).protocol_response
      assert_equal @response_data, protocol_response.data

      subject.remove(@name)
      protocol_response = subject.get(@name).protocol_response
      assert_not_equal @response_data, protocol_response.data
    end

    should "allow removing all responses" do
      subject.add(@name, @params){ @response_data }
      subject.add(@name){ @response_data }

      subject.remove_all
      protocol_response = subject.get(@name, @params).protocol_response
      assert_not_equal @response_data, protocol_response.data
      protocol_response = subject.get(@name).protocol_response
      assert_not_equal @response_data, protocol_response.data
    end

  end

end
