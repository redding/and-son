# AndSon's client class contains all the logic for connecting to a Sanford
# service host, sending a request and reading the server's response. It takes
# a host, port and version and then can be used to call multiple services with
# different parameters. Each time a service is called a TCP connection is made
# and the request is written and then the response read and returned. A client
# can optionally be given a timeout value, which will be used to wait for a
# response from the server. If the server doesn't respond before the timeout,
# then an exception is raised.
#
require 'sanford/request'
require 'sanford/response'
require 'socket'

require 'and-son/exceptions'

module AndSon

  class Client
    attr_reader :host, :port, :version, :timeout

    def initialize(host, port, version, options = nil)
      options ||= {}
      @host, @port = [ host, port ]
      @version = version
      @timeout = options[:timeout] || AndSon.listen_timeout
    end

    # Notes:
    # * TCP_NODELAY is set to disable buffering. In the case of Sanford
    #   communication, we have all the information we need to send up front and
    #   are closing the connection, so it doesn't need to buffer. See
    #   http://linux.die.net/man/7/tcp
    def call(name, params = {})
      socket = TCPSocket.new(self.host, self.port)
      socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, true)
      self.write_request(socket, name, self.version, params)
      ready = IO.select([ socket ], nil, nil, self.timeout)
      raise(AndSon::TimeoutError.new(name, self.version, self.timeout)) if !ready
      self.read_response(socket)
    ensure
      socket.close rescue false
    end

    protected

    def write_request(socket, name, version, params)
      request = Sanford::Request.new(name, version, params)
      socket.send(request.serialize, 0)
    end

    def read_response(socket)
      size = self.parse_response_size(socket)
      self.parse_response_protocol_version(socket)
      self.parse_response_body(socket, size)
    end

    def parse_response_size(socket)
      serialized_size = socket.recvfrom(Sanford::Response.number_size_bytes).first
      Sanford::Response.deserialize_size(serialized_size) || raise
    rescue Exception
      raise AndSon::BadResponseError, "The response size couldn't be parsed."
    end

    def parse_response_protocol_version(socket)
      matches = true
      serialized_version = socket.recvfrom(Sanford::Response.number_version_bytes).first
      matches = (serialized_version == Sanford::Response.serialized_protocol_version)
      raise if !matches
    rescue Exception
      message = if !matches
        "The protocol version didn't match the servers."
      else
        "The protocol version couldn't be parsed."
      end
      raise AndSon::BadResponseError, message
    end

    def parse_response_body(socket, size)
      serialized_response = socket.recvfrom(size).first
      Sanford::Response.parse(serialized_response)
    rescue Exception
      raise AndSon::BadResponseError, "The response body couldn't be parsed."
    end

  end

end
