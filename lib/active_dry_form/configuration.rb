# frozen_string_literal: true

module ActiveDryForm

  extend Dry::Configurable

  setting :strict_param_keys, default: defined?(::Rails) ? (::Rails.env.development? || ::Rails.env.test?) : true

  setting :form_class, default: 'active-dry-form'
  setting :error_class, default: 'form-error'
  setting :base_errors_class, default: 'form-base-error'

  setting :default_html_options do
    setting :input_check_box, default: {}
    setting :input_check_box_inline, default: {}
    setting :input_date, default: {}
    setting :input_datetime, default: {}
    setting :input_email, default: {}
    setting :input_file, default: {}
    setting :input_number, default: {}
    setting :input_password, default: {}
    setting :input_select, default: {}
    setting :input_telephone, default: {}
    setting :input_text_area, default: {}
    setting :input_text, default: {}
    setting :input_url, default: {}
  end

end

ActiveSupport::Reloader.to_prepare do
  ActiveDryForm.config.finalize!(freeze_values: true)
end
