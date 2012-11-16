class FakeServer

  def initialize(port)
    @port = port
    @handlers = {}
  end

  def add_handler(version, name, &block)
    @handlers["#{version}-#{name}"] = block
  end

  def run
    server = TCPServer.new("localhost", @port)
    socket = server.accept

    serve(socket)

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
        pid = fork do
          trap("TERM"){ exit }
          server.run
        end

        sleep 0.3 # Give time for the socket to start listening.
        yield
      ensure
        if pid
          Process.kill("TERM", pid)
          Process.wait(pid)
        end
      end
    end

  end

end
