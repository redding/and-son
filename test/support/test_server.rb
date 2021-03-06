require 'socket'

class TestServer

  def initialize(port, options = nil)
    options ||= {}
    @port = port
    @handlers = {}

    @closing_server = !!options[:closing_server]
    @slow = !!options[:slow]
  end

  def add_handler(name, &block)
    @handlers[name] = block
  end

  def run
    server = TCPServer.new('127.0.0.1', @port)
    socket = server.accept

    if @closing_server
      sleep 0.1 # ensure the connection isn't closed before a client can run
                # IO.select
      socket.close
    elsif @slow
      sleep 0.5
    else
      serve(socket)
    end

    server.close rescue false
  end

  protected

  def serve(socket)
    connection = Sanford::Protocol::Connection.new(socket)
    request = Sanford::Protocol::Request.parse(connection.read)
    status, result = route(request)
    response = Sanford::Protocol::Response.new(status, result)
    connection.write(response.to_hash)
    connection.close_write
  end

  def route(request)
    handler = @handlers[request.name]
    returned = handler.call(request.params)
  end

  module TestHelpers

    def run_test_server(server, &block)
      begin
        thread = Thread.new{ server.run }
        thread.join(JOIN_SECONDS)
        yield
      ensure
        sockaddr = Socket.pack_sockaddr_in(
          server.instance_variable_get("@port"),
          '127.0.0.1'
        )
        socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
        begin
          socket.connect_nonblock(sockaddr)
        rescue Errno::EINPROGRESS # socket is in the process of connecting
          IO.select(nil, [socket], nil, 1) # timeout after 1 second
        rescue StandardError
        end
        socket.close
        thread.join
      end
    end

    def start_closing_server(port, &block)
      server = FakeServer.new(port, :closing_server => true)
      run_test_server(server, &block)
    end

    def start_slow_server(port, &block)
      server = FakeServer.new(port, :slow => true)
      run_test_server(server, &block)
    end

  end

end
