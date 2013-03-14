require 'assert'
require 'and-son/stored_responses'

class AndSon::StoredResponses

  class BaseTest < Assert::Context
    desc "AndSon::StoredResponses"
    setup do
      @responses = AndSon::StoredResponses.new
    end
    subject{ @responses }

    should have_instance_methods :add, :remove, :find

  end

  class AddTest < BaseTest
    desc "add"

    should "allow adding responses given an name and optional params" do
      subject.add('test', { 'id' => 1 }) do
        Sanford::Protocol::Response.new([ 404, 'not found' ])
      end
      response = subject.find('test', { 'id' => 1 }).protocol_response

      assert_equal 404,         response.code
      assert_equal 'not found', response.status.message
      assert_equal nil,         response.data

      subject.add('test'){ Sanford::Protocol::Response.new([ 404, 'not found' ]) }
      response = subject.find('test').protocol_response

      assert_equal 404,         response.code
      assert_equal 'not found', response.status.message
      assert_equal nil,         response.data
    end

    should "default the response as a 200 when only given response data" do
      subject.add('test'){ true }
      response = subject.find('test').protocol_response

      assert_equal 200,   response.code
      assert_equal nil,   response.status.message
      assert_equal true,  response.data
    end

  end

  class FindTest < BaseTest
    desc "find"
    setup do
      @responses.add('test', { 'id' => 1 }){ true }
      @responses.add('test'){ true }
    end

    should "allow finding a response given a name and optional params" do
      response = subject.find('test', { 'id' => 1 }).protocol_response
      assert_equal true, response.data

      response = subject.find('test').protocol_response
      assert_equal true, response.data
    end

  end

  class RemoveTest < BaseTest
    desc "remove"
    setup do
      @responses.add('test', { 'id' => 1 }){ true }
      @responses.add('test'){ true }
    end

    should "remove responses given a name and optional params" do
      subject.remove('test', { 'id' => 1 })
      assert_nil subject.find('test', { 'id' => 1 })

      subject.remove('test')
      assert_nil      subject.find('test')
    end

  end

end
