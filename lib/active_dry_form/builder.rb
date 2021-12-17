# frozen_string_literal: true

module ActiveDryForm
  class Builder < ActionView::Helpers::FormBuilder

    def input(method, options = {})
      dry_tag = ActiveDryForm::Input.new(self, __method__, method, options)

      input_tag =
        case dry_tag.input_type
        when 'date'      then text_field(method, dry_tag.input_opts.merge('data-controller': 'flatpickr'))
        when 'date_time' then text_field(method, dry_tag.input_opts.merge('data-controller': 'flatpickr', 'data-flatpickr-enable-time': 'true'))
        when 'integer'   then number_field(method, dry_tag.input_opts)
        when 'bool'      then check_box(method, dry_tag.input_opts)
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
      dry_tag = ActiveDryForm::Input.new(self, __method__, method, options)
      dry_tag.wrap_tag select(method, collection, dry_tag.input_opts, html_options)
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

      tag.div class: 'callout alert' do
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

    def nested_attributes_association?(association_name)
      return unless @object.respond_to?(association_name)

      nested_association = @object.public_send(association_name)
      if nested_association.is_a?(Array)
        nested_association[0].is_a?(BaseForm)
      else
        nested_association.is_a?(BaseForm)
      end
    end

  end
end
