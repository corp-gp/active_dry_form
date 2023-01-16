# frozen_string_literal: true

module ActiveDryForm
  class Builder < ActionView::Helpers::FormBuilder

    include ActionView::Helpers::TagHelper
    include ActionView::Context

    def input(field, options = {})
      case input_type(field)
      when 'date'              then input_date(field, options)
      when 'time'              then input_datetime(field, options)
      when 'date-time'         then raise 'use :time instead :date_time (does not apply time zone) in params block'
      when 'integer', 'number' then input_number(field, options)
      when 'boolean'           then input_check_box(field, options)
      else
        case field.to_s
        when /password/ then input_password(field, options)
        when /email/    then input_email(field, options)
        when /phone/    then input_telephone(field, options)
        when /url/      then input_url(field, options)
        else input_text(field, options)
        end
      end
    end

    FIELDLESS_INPUT_TYPES = %w[check_box text_area].freeze

    %w[date datetime number password email url text file telephone check_box text_area].each do |input_type|
      builder_method = FIELDLESS_INPUT_TYPES.include?(input_type) ? input_type : "#{input_type}_field"

      class_eval <<~RUBY, __FILE__, __LINE__ + 1 # rubocop:disable Style/DocumentDynamicEvalDefinition
        def input_#{input_type}(method, options = {})
          wrap_input(__method__, method, options) do |input_options|
            #{builder_method}(method, input_options)
          end
        end
      RUBY
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

    private def input_type(field)
      (Array.wrap(object.info(field)[:type]) - %w[null]).first
    end

    private def wrap_input(method_type, method, options, wrapper_options = {})
      options = {
        required: object.info(method)[:required],
      }.merge(options)

      input_options =
        ActiveDryForm.config.default_html_options[method_type].merge(options) do |_key, oldval, newval|
          Array.wrap(oldval) + Array.wrap(newval)
        end

      ActiveDryForm::Input.new(self, method_type, method, options)
        .wrap_tag(yield(input_options), **wrapper_options)
    end

  end
end
