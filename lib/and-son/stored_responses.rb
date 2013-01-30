require 'sanford-protocol'
require 'and-son/response'

module AndSon

  class StoredResponses

    RequestData = Struct.new(:name, :params)

    def initialize
      @hash = {}
    end

    def add(name, params = nil)
      request_data = RequestData.new(name, params || {})
      response = yield
      if !response.kind_of?(Sanford::Protocol::Response)
        response = Sanford::Protocol::Response.new(200, response)
      end
      @hash[request_data] = AndSon::Response.new(response)
    end

    def find(name, params = nil)
      @hash[RequestData.new(name, params || {})]
    end

    def remove(name, params = nil)
      @hash.delete(RequestData.new(name, params || {}))
    end

  end

end
