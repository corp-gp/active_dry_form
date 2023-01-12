# frozen_string_literal: true

module ActiveDryForm

  extend Dry::Configurable

  setting :strict_param_keys, default: defined?(::Rails) ? (::Rails.env.development? || ::Rails.env.test?) : true

  setting :form_class, default: 'active-dry-form'
  setting :error_class, default: 'form-error'
  setting :base_errors_class, default: 'form-base-error'

  setting :default_html_options do
    setting :input do
      setting :date, default: {}
      setting :time, default: {}
      setting :integer, default: {}
      setting :boolean, default: {}
      setting :password, default: {}
      setting :email, default: {}
      setting :telephone, default: {}
      setting :url, default: {}
      setting :text, default: {}
    end
    setting :input_select, default: {}
    setting :input_checkbox_inline, default: {}
    setting :input_text, default: {}
    setting :input_text_area, default: {}
    setting :input_file, default: {}
  end

end

ActiveSupport::Reloader.to_prepare do
  ActiveDryForm.config.finalize!(freeze_values: true)
end
