# AndSon's Connection class extends the Connection class provided by
# Sanford-Protocol. Instead of taking a socket directly, it takes just the host
# and port and creates it's own socket. In addition to doing this, it provides
# a `ready_to_read?` method which can be used to see if a socket is ready to be
# read from or not. Connections take a timeout value that will be used in
# conjuction with `IO.select` to check if a socket is ready to be read from. If
# a socket is not ready within the time limit, the method returns false.
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
      socket.setsockopt(::Socket::IPPROTO_TCP, ::Socket::TCP_NODELAY, true)
      super(socket)
    end

    # IO.select takes array's of IO objects and returns when one of them is
    # ready. The first parameter is for IO objects that you want to read from.
    # In this case, we are waiting for our socket to be ready for reading and
    # using a timeout to limit how long we wait. If nothing is ready within the
    # timeout, IO.select returns nil.
    def ready_to_read?
      !!IO.select([ @socket ], nil, nil, self.timeout)
    end

    def close
      @socket.close rescue false
    end

  end

end
