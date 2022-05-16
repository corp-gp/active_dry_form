# frozen_string_literal: true

require 'dry/configurable/test_interface'

module ActiveDryForm

  enable_test_interface

end


RSpec.configure do |config|
  config.before(:each) do
    ActiveDryForm.reset_config
  end
end
