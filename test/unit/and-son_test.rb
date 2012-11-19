require 'assert'

module AndSon

  class BaseTest < Assert::Context
    desc "AndSon"
    subject{ AndSon }

    should have_instance_methods :new

  end

end
