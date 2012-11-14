require 'sanford-protocol/test/fake_socket'

class FakeServer

  def initialize
    @services = {}
    @socket = Sanford::Protocol::Test::FakeSocket.new
  end

  def add_service(version, name, &block)
    @services["#{version}-#{name}"] = block
  end

  # Socket methods

  def setsockopt(*args)
  end

  def send(bytes, flag)
    self.process(bytes)
  end

  def recvfrom(*args)
    @socket.recvfrom(*args)
  end

  protected

  def process(bytes)
    request = self.read_request(bytes)
    block = @services["#{request.version}-#{request.name}"]
    if block
      returned = block.call(request.params)
      self.write_response(*returned)
    end
  end

  def read_request(bytes)
    socket = Sanford::Protocol::Test::FakeSocket.new(bytes)
    connection = Sanford::Protocol::Connection.new(socket)
    Sanford::Protocol::Request.parse(connection.read)
  end

  def write_response(*args)
    socket = Sanford::Protocol::Test::FakeSocket.new
    connection = Sanford::Protocol::Connection.new(socket)
    response = Sanford::Protocol::Response.new(*args)
    connection.write(response.to_hash)
    @socket.reset(socket.out)
  end

end
