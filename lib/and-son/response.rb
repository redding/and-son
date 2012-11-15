require 'sanford-protocol'

require 'and-son/exceptions'

module AndSon

  class Response

    CODE_MATCHERS = {
      '400' => 400,
      '404' => 404,
      '4xx' => /4[0-9][0-9]/,
      '5xx' => /5[0-9][0-9]/
    }

    def self.parse(hash)
      self.new(Sanford::Protocol::Response.parse(hash))
    end

    attr_reader :protocol_response

    def initialize(protocol_response)
      @protocol_response = protocol_response
    end

    def data
      if self.code_is_5xx?
        raise ServerError, self.protocol_response.status.message
      elsif self.code_is_404?
        raise NotFoundError, self.protocol_response.status.message
      elsif self.code_is_400?
        raise BadRequestError, self.protocol_response.status.message
      elsif self.code_is_4xx?
        raise ClientError, self.protocol_response.status.message
      else
        self.protocol_response.data
      end
    end

    CODE_MATCHERS.each do |name, matcher|
      matcher = matcher.kind_of?(Regexp) ? matcher : Regexp.new(matcher.to_s)

      define_method("code_is_#{name}?") do
        self.protocol_response.code.to_s =~ matcher
      end
    end

  end

end
