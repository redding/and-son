require 'and-son/client'
require 'and-son/version'

module AndSon

  def self.new(*args)
    AndSon::Client.new(*args)
  end

end
