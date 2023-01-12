# frozen_string_literal: true

module ActiveDryForm
  class Builder < ActionView::Helpers::FormBuilder

    include ActionView::Helpers::TagHelper
    include ActionView::Context

    def input(method, options = {})
      dry_tag = ActiveDryForm::Input.new(self, __method__, method, options)

      input_tag =
        case dry_tag.input_type
        when 'date'      then date_field(method, input_options(dry_tag, defaults.input.date))
        when 'time'      then datetime_field(method, input_options(dry_tag, defaults.input.time))
        when 'date-time' then raise 'use :time instead :date_time (does not apply time zone) in params block'
        when 'integer'   then number_field(method, input_options(dry_tag, defaults.input.integer))
        when 'boolean'   then check_box(method, input_options(dry_tag, defaults.input.boolean))
        else
          case method.to_s
          when /password/ then password_field(method, input_options(dry_tag, defaults.input.password))
          when /email/    then email_field(method, input_options(dry_tag, defaults.input.email))
          when /phone/    then telephone_field(method, input_options(dry_tag, defaults.input.telephone))
          when /url/      then url_field(method, input_options(dry_tag, defaults.input.url))
          else text_field(method, input_options(dry_tag, defaults.input.text))
          end
        end

      dry_tag.wrap_tag input_tag
    end

    def input_select(method, collection, options = {}, html_options = {}) # rubocop:disable Gp/OptArgParameters
      dry_tag = ActiveDryForm::Input.new(self, __method__, method, html_options)
      dry_tag.wrap_tag select(method, collection, options, input_options(dry_tag, defaults.input_select))
    end

    def input_checkbox_inline(method, options = {})
      dry_tag = ActiveDryForm::Input.new(self, __method__, method, options)
      dry_tag.wrap_tag check_box(method, input_options(dry_tag, defaults.input_checkbox_inline)), label_last: true
    end

    def input_text(method, options = {})
      dry_tag = ActiveDryForm::Input.new(self, __method__, method, options)
      dry_tag.wrap_tag text_field(method, input_options(dry_tag, defaults.input_text))
    end

    def input_text_area(method, options = {})
      dry_tag = ActiveDryForm::Input.new(self, __method__, method, options)
      dry_tag.wrap_tag text_area(method, input_options(dry_tag, defaults.input_text_area))
    end

    def input_file(method, options = {})
      dry_tag = ActiveDryForm::Input.new(self, __method__, method, options)
      dry_tag.wrap_tag file_field(method, input_options(dry_tag, defaults.input_file))
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

    private def defaults
      @defaults ||= ActiveDryForm.config.default_html_options
    end

    private def input_options(dry_tag, default_options)
      default_options.merge(dry_tag.input_opts) do |_key, oldval, newval|
        Array.wrap(oldval) + Array.wrap(newval)
      end
    end

  end
end
