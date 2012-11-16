module AndSon

  class RequestError < RuntimeError
    attr_reader :response

    def initialize(protocol_response)
      super(protocol_response.status.message)
      @response = protocol_response
    end
  end

  ClientError     = Class.new(RequestError)

  BadRequestError = Class.new(ClientError)
  NotFoundError   = Class.new(ClientError)

  ServerError     = Class.new(RequestError)

end
