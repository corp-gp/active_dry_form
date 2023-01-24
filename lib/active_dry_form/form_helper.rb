# frozen_string_literal: true

module ActiveDryForm
  module FormHelper

    def active_dry_form_for(name, options = {}, &block)
      options[:builder] = ActiveDryForm::Builder
      options[:html] = html_options(options)

      # Array.wrap because Hash === name, it breaks polymorphic_path
      # TODO: refactor to options[:url]
      form_for(Array.wrap(name), options) do |f|
        concat f.show_base_errors
        instance_exec(f, &block)
      end
    end

    private def html_options(options)
      return ActiveDryForm.config.html_options.form unless options[:html]

      options[:html].merge(ActiveDryForm.config.html_options.form) do |_key, oldval, newval|
        Array.wrap(newval) + Array.wrap(oldval)
      end
    end

  end
end

ActiveSupport.on_load(:action_view) do
  include ActiveDryForm::FormHelper
end
