# frozen_string_literal: true

module ActiveDryForm

  extend Dry::Configurable
  include Dry::Core::Constants

  setting :strict_param_keys, default: defined?(::Rails) ? (::Rails.env.development? || ::Rails.env.test?) : true

  setting :css_classes do
    setting :form,       default: 'active-dry-form'
    setting :error,      default: 'form-error'
    setting :base_error, default: 'form-base-error'
    setting :hint,       default: 'form-hint'
  end

  setting :html_options do
    setting :input_check_box,        default: EMPTY_HASH
    setting :input_check_box_inline, default: EMPTY_HASH
    setting :input_date,             default: EMPTY_HASH
    setting :input_datetime,         default: EMPTY_HASH
    setting :input_email,            default: EMPTY_HASH
    setting :input_file,             default: EMPTY_HASH
    setting :input_number,           default: EMPTY_HASH
    setting :input_password,         default: EMPTY_HASH
    setting :input_select,           default: EMPTY_HASH
    setting :input_telephone,        default: EMPTY_HASH
    setting :input_text_area,        default: EMPTY_HASH
    setting :input_text,             default: EMPTY_HASH
    setting :input_url,              default: EMPTY_HASH
  end

end

ActiveSupport::Reloader.to_prepare do
  ActiveDryForm.config.finalize!(freeze_values: true)
end
