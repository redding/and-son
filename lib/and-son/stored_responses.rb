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
      response = handle_response_block(response_block)
      AndSon::Response.new(response)
    end

    def remove(name, params = nil)
      @hash.delete(RequestData.new(name, params || {}))
    end

    def remove_all
      @hash.clear
    end

    private

    def handle_response_block(response_block)
      if response_block.arity == 0 || response_block.arity == -1
        default_response.tap{ |r| r.data = response_block.call }
      else
        default_response.tap{ |r| response_block.call(r) }
      end
    end

    def default_response
      Sanford::Protocol::Response.new(200, {})
    end

    def default_response_proc
      proc{ |r| r.data = Hash.new }
    end

  end

end
