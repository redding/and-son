module AndSon

  class RequestError < RuntimeError; end

  class ClientError < RequestError; end

  class BadRequestError < ClientError; end
  class NotFoundError < ClientError; end

  class ServerError < RequestError; end

end
