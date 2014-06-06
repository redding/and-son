class FakeConnection

  attr_reader :written

  def initialize
    @written = []
  end

  def peek(*args)
    "peek_data"
  end

  def read(*args)
    { 'status' => [ 200 ], 'data' => {} }
  end

  def write(request_hash)
    @written << request_hash
  end

  def close_write
    @write_stream_closed = true
  end

  def write_stream_closed?
    !!@write_stream_closed
  end

end
