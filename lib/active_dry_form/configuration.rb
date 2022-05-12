# frozen_string_literal: true

module ActiveDryForm

  class Configuration

    extend Dry::Configurable

    default_strict_param_keys =
      if defined?(::Rails)
        ::Rails.env.development? || ::Rails.env.test?
      else
        true
      end

    setting :strict_param_keys, default_strict_param_keys

  end

end

ActiveSupport::Reloader.to_prepare do
  ActiveDryForm::Configuration.config.finalize!(freeze_values: true)
end
