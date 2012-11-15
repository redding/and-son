# AndSon's main module provides a convenience method for creating clients
# (`new`) and supports a few configuration options.
#
require 'ns-options'

require 'and-son/client'
require 'and-son/version'

module AndSon
  include NsOptions

  options :config do
    option :listen_timeout, Numeric, :default => 10
  end

  def self.new(*args)
    AndSon::Client.new(*args)
  end

end
