# frozen_string_literal: true

module ActiveDryForm
  module FormHelper

    def active_dry_form_for(name, options = {}, &block)
      options = options.dup
      options[:builder] = ActiveDryForm::Builder
      options[:html] ||= {}
      ActiveDryForm.config.html_options.form.each do |key, value|
        options[:html][key] = Array.wrap(value) + Array.wrap(options[:html][key])
      end

      # Array.wrap because Hash === name, it breaks polymorphic_path
      # TODO: refactor to options[:url]
      form_for(Array.wrap(name), options) do |f|
        concat f.show_base_errors
        instance_exec(f, &block)
      end
    end

  end
end

ActiveSupport.on_load(:action_view) do
  include ActiveDryForm::FormHelper
end
