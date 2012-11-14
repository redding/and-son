#
# Notes:
# * TCP_NODELAY is set to disable buffering. In the case of Sanford
#   communication, we have all the information we need to send up front and
#   are closing the connection, so it doesn't need to buffer. See
#   http://linux.die.net/man/7/tcp
#
require 'sanford-protocol'
require 'socket'

module AndSon

  class Connection < Sanford::Protocol::Connection

    attr_reader :timeout

    def initialize(host, port, timeout)
      @timeout = timeout

      socket = TCPSocket.new(host, port)
      socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, true)
      super(socket)
    end

    # IO.select takes array's of IO objects and returns when one of them is
    # ready. The first parameter is for IO objects that you want to read from.
    # In this case, we are waiting for our socket to be ready for reading and
    # using a timeout to limit how long we wait. If nothing is ready within the
    # timeout, IO.select returns nil.
    def ready_to_read?
      !!IO.select([ self.socket ], nil, nil, self.timeout)
    end

    def close
      socket.close rescue false
    end

  end

end
