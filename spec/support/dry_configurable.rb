# frozen_string_literal: true

require "dry/configurable/test_interface"

module ActiveDryForm

  class Configuration

    enable_test_interface

  end

end


RSpec.configure do |config|
  config.before(:each) do
    ActiveDryForm::Configuration.reset_config
  end
end
