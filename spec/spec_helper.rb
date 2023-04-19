# frozen_string_literal: true

require 'bundler'
Bundler.require :default

Dir["#{File.dirname(__FILE__)}/support/*.rb"].sort.each { |f| require f }

I18n.load_path = Dir.glob("#{__dir__}/app/*.yml")
I18n.available_locales = %i[ru en]
I18n.default_locale = :en


RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
