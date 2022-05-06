# frozen_string_literal: true

module ActiveDryForm
  class BaseContract < Dry::Validation::Contract

    config.messages.load_paths << 'config/locales/dry_validation.ru.yml'
    config.messages.default_locale = :ru

  end
end
