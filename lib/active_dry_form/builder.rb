# frozen_string_literal: true

module ActiveDryForm
  class Builder < ActionView::Helpers::FormBuilder

    include ActionView::Helpers::TagHelper
    include ActionView::Context

    def input(method, options = {})
      dry_tag = ActiveDryForm::Input.new(self, __method__, method, options)

      input_tag =
        case dry_tag.input_type
        when 'date'      then text_field(method, dry_tag.input_opts.merge('data-controller': 'flatpickr'))
        when 'date-time' then text_field(method, dry_tag.input_opts.merge('data-controller': 'flatpickr', 'data-flatpickr-enable-time': 'true'))
        when 'integer'   then number_field(method, dry_tag.input_opts)
        when 'boolean'   then check_box(method, dry_tag.input_opts)
        else
          case method.to_s
          when /password/ then password_field(method, dry_tag.input_opts)
          when /email/    then email_field(method, dry_tag.input_opts)
          when /phone/    then telephone_field(method, dry_tag.input_opts)
          when /url/      then url_field(method, dry_tag.input_opts)
          else text_field(method, dry_tag.input_opts)
          end
        end

      dry_tag.wrap_tag input_tag
    end

    def input_select(method, collection, options = {}, html_options = {}) # rubocop:disable Gp/OptArgParameters
      dry_tag = ActiveDryForm::Input.new(self, __method__, method, html_options)
      dry_tag.wrap_tag select(method, collection, options, dry_tag.input_opts.merge('data-controller': 'select-tag'))
    end

    def input_checkbox_inline(method, options = {})
      dry_tag = ActiveDryForm::Input.new(self, __method__, method, options)
      dry_tag.wrap_tag check_box(method, dry_tag.input_opts), label_last: true
    end

    def input_text(method, options = {})
      dry_tag = ActiveDryForm::Input.new(self, __method__, method, options)
      dry_tag.wrap_tag text_area(method, dry_tag.input_opts)
    end

    def input_file(method, options = {})
      dry_tag = ActiveDryForm::Input.new(self, __method__, method, options)
      dry_tag.wrap_tag file_field(method, dry_tag.input_opts)
    end

    def input_hidden(method, options = {})
      hidden_field(method, options)
    end

    def show_base_errors
      return unless @object.base_errors

      tag.div class: 'callout alert form-base-error' do
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

  end
end
