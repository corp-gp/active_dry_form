# frozen_string_literal: true

module ActiveDryForm
  module FormHelper

    def active_dry_form_for(name, options = {}, &block)
      options[:builder] = ActiveDryForm::Builder
      options[:html] ||= {}
      options[:html][:class] = "#{ActiveDryForm.config.form_class} #{options[:html][:class]}"

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
