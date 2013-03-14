require 'socket'

class FakeServer

  def initialize(port, options = nil)
    options ||= {}
    @port = port
    @handlers = {}

    @closing_server = !!options[:closing_server]
  end

  def add_handler(version, name, &block)
    @handlers["#{version}-#{name}"] = block
  end

  def run
    server = TCPServer.new("localhost", @port)
    socket = server.accept

    if @closing_server
      sleep 0.1 # ensure the connection isn't closed before a client can run
                # IO.select
      socket.close
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
  end

  def route(request)
    handler = @handlers["#{request.version}-#{request.name}"]
    returned = handler.call(request.params)
  end

  module Helper

    def run_fake_server(server, &block)
      begin
        thread = Thread.new{ server.run }
        yield
      ensure
        begin
          TCPSocket.open("localhost", server.instance_variable_get("@port"))
        rescue Exception
        end
        thread.join
      end
    end

    def start_closing_server(port, &block)
      server = FakeServer.new(port, :closing_server => true)
      run_fake_server(server, &block)
    end

  end

end
