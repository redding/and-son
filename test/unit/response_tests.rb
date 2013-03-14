require 'assert'
require 'and-son/response'

class AndSon::Response

  class BaseTests < Assert::Context
    desc "AndSon::Response"
    setup do
      @protocol_response = Sanford::Protocol::Response.new([ 200, 'message' ], 'data')
      @response = AndSon::Response.new(@protocol_response)
    end
    subject{ @response }

    should have_imeths :data, :code_is_5xx?, :code_is_404?, :code_is_400?, :code_is_4xx?
    should have_cmeths :parse

    should "return the protocol response's data with #data" do
      assert_equal @protocol_response.data, subject.data
    end
    should "return false for all the code_is methods" do
      assert_equal false, subject.code_is_5xx?
      assert_equal false, subject.code_is_404?
      assert_equal false, subject.code_is_400?
      assert_equal false, subject.code_is_4xx?
    end

  end

  class FailedResponseTests < BaseTests
    desc "given a failed response"
    setup do
      @protocol_response = Sanford::Protocol::Response.new([ 500, 'message' ])
      @response = AndSon::Response.new(@protocol_response)
    end

    should "raise an exception using the response's message and the exception should have the" \
           "response as well" do
      exception = nil
      begin; subject.data; rescue Exception => exception; end

      assert_instance_of AndSon::ServerError,         exception
      assert_equal @protocol_response.status.message, exception.message
      assert_equal @protocol_response,                exception.response
    end

  end

  class Response5xxTests < BaseTests
    desc "given a 5xx response"
    setup do
      @protocol_response = Sanford::Protocol::Response.new(500)
      @response = AndSon::Response.new(@protocol_response)
    end

    should "return true with code_is_5xx? and false for all the other code_is methods" do
      assert_equal true,  subject.code_is_5xx?
      assert_equal false, subject.code_is_404?
      assert_equal false, subject.code_is_400?
      assert_equal false, subject.code_is_4xx?
    end

  end

  class Response404Tests < BaseTests
    desc "given a 404 response"
    setup do
      @protocol_response = Sanford::Protocol::Response.new(404)
      @response = AndSon::Response.new(@protocol_response)
    end

    should "return true with code_is_404? and code_is_4xx?; false for all the other " \
           "code_is methods" do
      assert_equal false, subject.code_is_5xx?
      assert_equal true,  subject.code_is_404?
      assert_equal false, subject.code_is_400?
      assert_equal true,  subject.code_is_4xx?
    end

  end

  class Response400Tests < BaseTests
    desc "given a 400 response"
    setup do
      @protocol_response = Sanford::Protocol::Response.new(400)
      @response = AndSon::Response.new(@protocol_response)
    end

    should "return true with code_is_400? and code_is_4xx?; false for all the other " \
           "code_is methods" do
      assert_equal false, subject.code_is_5xx?
      assert_equal false, subject.code_is_404?
      assert_equal true,  subject.code_is_400?
      assert_equal true,  subject.code_is_4xx?
    end

  end

  class Response4xxTests < BaseTests
    desc "given a 4xx response"
    setup do
      @protocol_response = Sanford::Protocol::Response.new(402)
      @response = AndSon::Response.new(@protocol_response)
    end

    should "return true with code_is_4xx? and false for all the other code_is methods" do
      assert_equal false, subject.code_is_5xx?
      assert_equal false, subject.code_is_404?
      assert_equal false, subject.code_is_400?
      assert_equal true,  subject.code_is_4xx?
    end

  end

end

