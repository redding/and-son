require 'sanford-protocol'
require 'and-son/response'

module AndSon

  class StoredResponses

    def initialize
      @hash = Hash.new{ |h, k| h[k] = Stub.new }
    end

    def add(name, &block)
      @hash[name].tap{ |s| s.set_default_proc(&block) }
    end

    def get(name, params)
      response = @hash[name].call(params)
      AndSon::Response.new(response)
    end

    def remove(name)
      @hash.delete(name)
    end

    def remove_all
      @hash.clear
    end

    class Stub
      attr_reader :hash

      def initialize
        @default_proc = proc{ |r| r.data = Hash.new }
        @hash = {}
      end

      def set_default_proc(&block)
        @default_proc = block if block
      end

      def with(params, &block)
        @hash[params] = block
        self
      end

      def call(params)
        block = @hash[params] || @default_proc
        if block.arity == 0 || block.arity == -1
          default_response.tap{ |r| r.data = block.call }
        else
          default_response.tap{ |r| block.call(r) }
        end
      end

      private

      def default_response
        Sanford::Protocol::Response.new(200, {})
      end
    end

  end

end
