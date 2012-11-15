# AndSon's Client is the primary class for the gem. It is a simple client for
# communicating with a Sanford server. It takes a host and port (the server to
# connect to) and the version of the services it wants to make requests against.
# It's `call` handles making a request and reading the server's response. All
# requests are limited by a timeout, to keep clients from hanging forever,
# waiting on a server. If a server doesn't respond within this time limit, an
# exception is raised.
#
require 'sanford-protocol'

require 'and-son/connection'

module AndSon

  class Client
    attr_reader :host, :port, :version

    def initialize(host, port, version)
      options ||= {}
      @host, @port = [ host, port ]
      @version = version
    end

    def call(name, params = {}, timeout = nil)
      timeout ||= (ENV['ANDSON_REQUEST_TIMEOUT'] || 60).to_i
      connection = AndSon::Connection.new(self.host, self.port, timeout)
      request = self.request(name, params)
      connection.write(request.to_hash)
      if connection.ready_to_read?
        self.response(connection.read)
      else
        raise(AndSon::TimeoutError.new(request, timeout))
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
