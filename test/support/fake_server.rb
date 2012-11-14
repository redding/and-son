require 'sanford-protocol/test/fake_socket'

class FakeServer < Sanford::Protocol::Test::FakeSocket

  def initialize
    @services = {}
    super
  end

  def add_service(version, name, &block)
    @services["#{version}-#{name}"] = block
  end

  # Socket methods

  def setsockopt(*args)
  end

  def send(bytes, flag)
    super(bytes, flag)
    self.process(self.written)
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
    socket = Sanford::Protocol::Test::FakeSocket.new
    socket.add_to_read_stream(bytes)
    connection = Sanford::Protocol::Connection.new(socket)
    Sanford::Protocol::Request.parse(connection.read)
  end

  def write_response(*args)
    socket = Sanford::Protocol::Test::FakeSocket.new
    connection = Sanford::Protocol::Connection.new(socket)
    response = Sanford::Protocol::Response.new(*args)
    connection.write(response.to_hash)
    self.add_to_read_stream(socket.written)
  end

end
