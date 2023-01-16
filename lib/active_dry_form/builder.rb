# frozen_string_literal: true

module ActiveDryForm
  class Builder < ActionView::Helpers::FormBuilder

    include ActionView::Helpers::TagHelper
    include ActionView::Context

    def input(method, options = {})
      wrap_input(__method__, method, options) do |input_options, input_type|
        case input_type
        when :boolean then check_box(method, input_options)
        else public_send("#{input_type}_field", method, input_options)
        end
      end
    end

    def input_select(method, collection, options = {}, html_options = {}) # rubocop:disable Gp/OptArgParameters
      wrap_input(__method__, method, html_options) do |input_options|
        select(method, collection, options, input_options)
      end
    end

    def input_checkbox_inline(method, options = {})
      wrap_input(__method__, method, options, label_last: true) do |input_options|
        check_box(method, input_options)
      end
    end

    def input_text(method, options = {})
      wrap_input(__method__, method, options) do |input_options|
        text_field(method, input_options)
      end
    end

    def input_text_area(method, options = {})
      wrap_input(__method__, method, options) do |input_options|
        text_area(method, input_options)
      end
    end

    def input_file(method, options = {})
      wrap_input(__method__, method, options) do |input_options|
        file_field(method, input_options)
      end
    end

    def input_hidden(method, options = {})
      hidden_field(method, options)
    end

    def show_base_errors
      return unless @object.base_errors

      tag.div class: ActiveDryForm.config.base_errors_class do
        tag.ul do
          # внутри ошибки может быть html
          @object.base_errors.map { tag.li _1.html_safe }.join.html_safe
        end
      end
    end

    def show_error(method)
      ActiveDryForm::Input.new(self, __method__, method, {}).error_text
    end

    def button(value = nil, options = {}, &block) # rubocop:disable Gp/OptArgParameters
      options[:class] = [options[:class], 'button'].compact
      super(value, options, &block)
    end

    def fields_for(association_name, fields_options = {}, &block)
      fields_options[:builder] ||= options[:builder]
      fields_options[:namespace] = options[:namespace]
      fields_options[:parent_builder] = self

      association = @object.public_send(association_name)

      if association.is_a?(BaseForm)
        fields_for_nested_model("#{@object_name}[#{association_name}]", association, fields_options, block)
      elsif association.respond_to?(:to_ary)
        field_name_regexp = Regexp.new(Regexp.escape("#{@object_name}[#{association_name}][") << '\d+\]') # хак для замены хеша на массив
        output = ActiveSupport::SafeBuffer.new
        Array.wrap(association).each do |child|
          output << fields_for_nested_model("#{@object_name}[#{association_name}][]", child, fields_options, block)
            .gsub(field_name_regexp, "#{@object_name}[#{association_name}][]").html_safe
        end
        output
      end
    end

    private def wrap_input(method_type, method, options, wrapper_options = {})
      dry_tag = ActiveDryForm::Input.new(self, method_type, method, options)
      dry_tag.wrap_tag yield(dry_tag.input_options, dry_tag.input_type), **wrapper_options
    end

  end
end
