# AndSon's Client is the
#
require 'sanford-protocol'

require 'and-son/connection'

module AndSon

  class Client
    attr_reader :host, :port, :version, :timeout

    def initialize(host, port, version, options = nil)
      options ||= {}
      @host, @port = [ host, port ]
      @version = version
      @timeout = options[:timeout] || AndSon.listen_timeout
    end

    def call(name, params = {})
      connection = AndSon::Connection.new(self.host, self.port, self.timeout)
      request = self.request(name, params)
      connection.write(request.to_hash)
      if connection.ready_to_read?
        self.response(connection.read)
      else
        raise(AndSon::TimeoutError.new(request, connection.timeout))
      end
    ensure
      connection.close if connection
    end

    protected

    def request(name, params)
      Sanford::Protocol::Request.new(self.version, name, params)
    end

    def response(hash)
      Sanford::Protocol::Response.parse(hash)
    end

  end

  class TimeoutError < RuntimeError
    attr_reader :message

    def initialize(request, timeout)
      @message = "The request, #{request.version.inspect} #{request.name.inspect}, " \
        "didn't respond in #{timeout} seconds or less."
    end
  end

end
