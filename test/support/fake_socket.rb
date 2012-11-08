class FakeSocket < IO
  attr_reader :write_stream, :read_stream

  def initialize(host, port, io_mode = 'r+')
    @host, @port = [ host, port ]
    @read_stream = ""
    @write_stream = []
    super(IO.sysopen("/dev/null", io_mode), io_mode)
  end

  def add_to_read_stream(message)
    @read_stream += message
  end

  def setsockopt(*args)
  end

  def send(message, flag)
    @write_stream << message
  end

  def recvfrom(size)
    [ @read_stream.slice!(0, size) ]
  end

end
