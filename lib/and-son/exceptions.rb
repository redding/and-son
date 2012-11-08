module AndSon

  class TimeoutError < RuntimeError

    def initialize(name, version, timeout)
      @message = "The call to the service #{name.inspect} version #{version.inspect} " \
        "didn't respond in #{timeout} seconds or less."
    end

  end

  class BadResponseError < RuntimeError; end

end
