require 'socket'
require 'sanford-protocol'

module AndSon

  class Connection < Struct.new(:host, :port)
    module NoRequest
      def self.to_s; "[?]"; end
    end

    def open
      protocol_connection = Sanford::Protocol::Connection.new(tcp_socket)
      yield protocol_connection if block_given?
    ensure
      protocol_connection.close if protocol_connection
    end

    private

    # TCP_NODELAY is set to disable buffering. In the case of Sanford
    # communication, we have all the information we need to send up front and
    # are closing the connection, so it doesn't need to buffer.
    # See http://linux.die.net/man/7/tcp

    def tcp_socket
      TCPSocket.new(host, port).tap do |socket|
        socket.setsockopt(::Socket::IPPROTO_TCP, ::Socket::TCP_NODELAY, true)
      end
    end

  end

end
