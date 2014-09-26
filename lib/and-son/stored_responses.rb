require 'sanford-protocol'
require 'and-son/response'

module AndSon

  class StoredResponses

    RequestData = Struct.new(:name, :params)

    def initialize
      @hash = Hash.new{ default_response_proc }
    end

    def add(name, params = nil, &response_block)
      request_data = RequestData.new(name, params || {})
      @hash[request_data] = response_block
    end

    def get(name, params = nil)
      response_block = @hash[RequestData.new(name, params || {})]
      response = response_block.call
      if !response.kind_of?(Sanford::Protocol::Response)
        response = Sanford::Protocol::Response.new(200, response)
      end
      AndSon::Response.new(response)
    end

    def remove(name, params = nil)
      @hash.delete(RequestData.new(name, params || {}))
    end

    private

    def default_response_proc
      proc{ Sanford::Protocol::Response.new(200, {}) }
    end

  end

end
