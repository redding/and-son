require 'assert'
require 'and-son'

module AndSon

  class UnitTests < Assert::Context
    desc "AndSon"
    subject{ AndSon }

    should have_imeths :new

  end

end
