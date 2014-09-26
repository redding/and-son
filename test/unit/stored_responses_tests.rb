require 'assert'
require 'and-son/stored_responses'

class AndSon::StoredResponses

  class UnitTests < Assert::Context
    desc "AndSon::StoredResponses"
    setup do
      @responses = AndSon::StoredResponses.new
    end
    subject{ @responses }

    should have_imeths :add, :remove, :get

  end

  class AddTest < UnitTests
    desc "add"

    should "allow adding responses given an name and optional params" do
      subject.add('test', { 'id' => 1 }) do
        Sanford::Protocol::Response.new([ 404, 'not found' ])
      end
      response = subject.get('test', { 'id' => 1 }).protocol_response

      assert_equal 404,         response.code
      assert_equal 'not found', response.status.message
      assert_equal nil,         response.data

      subject.add('test'){ Sanford::Protocol::Response.new([ 404, 'not found' ]) }
      response = subject.get('test').protocol_response

      assert_equal 404,         response.code
      assert_equal 'not found', response.status.message
      assert_equal nil,         response.data
    end

    should "default the response as a 200 when only given response data" do
      subject.add('test'){ true }
      response = subject.get('test').protocol_response

      assert_equal 200,  response.code
      assert_equal nil,  response.status.message
      assert_equal true, response.data
    end

  end

  class GetTest < UnitTests
    desc "get"
    setup do
      @responses.add('test', { 'id' => 1 }){ true }
      @responses.add('test'){ true }
      @service_called = false
      @responses.add('call_service'){ @service_called = true }
    end

    should "return a default response with a name/params that aren't configured" do
      response = subject.get(Factory.string, { Factory.string => Factory.string })
      protocol_response = response.protocol_response
      assert_equal 200, protocol_response.code
      assert_nil protocol_response.status.message
      assert_equal({}, protocol_response.data)
    end

    should "allow geting a response given a name and optional params" do
      response = subject.get('test', { 'id' => 1 }).protocol_response
      assert_equal true, response.data

      response = subject.get('test').protocol_response
      assert_equal true, response.data
    end

    should "not call the response block until `get` is called" do
      assert_false @service_called
      subject.get('call_service')
      assert_true @service_called
    end

  end

  class RemoveTest < UnitTests
    desc "remove"
    setup do
      @responses.add('test', { 'id' => 1 }){ true }
      @responses.add('test'){ true }
    end

    should "remove responses given a name and optional params" do
      response = subject.get('test', { 'id' => 1 })
      assert_equal true, response.data

      subject.remove('test', { 'id' => 1 })
      response = subject.get('test', { 'id' => 1 })
      assert_not_equal true, response.data

      response = subject.get('test')
      assert_equal true, response.data

      subject.remove('test')
      response = subject.get('test')
      assert_not_equal true, response.data
    end

  end

end
