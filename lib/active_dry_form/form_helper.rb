# frozen_string_literal: true

module ActiveDryForm
  module FormHelper

    def active_dry_form_for(name, options = {})
      options[:builder] = ActiveDryForm::Builder
      options[:html] ||= {}
      options[:html][:class] = "active-dry-form #{options[:html][:class]}"

      form_for(name, options) do |f|
        concat f.show_base_errors
        yield(f)
      end
    end

  end
end

ActiveSupport.on_load(:action_view) do
  include ActiveDryForm::FormHelper
end
