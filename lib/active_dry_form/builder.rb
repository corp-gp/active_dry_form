# frozen_string_literal: true

module ActiveDryForm
  class Builder < ActionView::Helpers::FormBuilder

    include ActionView::Helpers::TagHelper
    include ActionView::Context
    include Dry::Core::Constants

    def input(field, options = {})
      case input_type(field)
      when 'date'              then input_date(field, options)
      when 'time'              then input_datetime(field, options)
      when 'date-time'         then raise DateTimeNotAllowedError, 'use :time instead of :date_time (does not apply timezone) in params block'
      when 'integer'           then input_integer(field, options)
      when 'number'            then input_number(field, options)
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

    def input_date(field, options = {});      wrap_input(__method__, field, options) { |opts| date_field(field, opts) } end
    def input_datetime(field, options = {});  wrap_input(__method__, field, options) { |opts| datetime_field(field, opts) } end
    def input_integer(field, options = {});   wrap_input(__method__, field, options) { |opts| number_field(field, opts) } end
    def input_number(field, options = {});    wrap_input(__method__, field, options) { |opts| number_field(field, opts) } end
    def input_password(field, options = {});  wrap_input(__method__, field, options) { |opts| password_field(field, opts) } end
    def input_email(field, options = {});     wrap_input(__method__, field, options) { |opts| email_field(field, opts) } end
    def input_url(field, options = {});       wrap_input(__method__, field, options) { |opts| url_field(field, opts) } end
    def input_text(field, options = {});      wrap_input(__method__, field, options) { |opts| text_field(field, opts) } end
    def input_file(field, options = {});      wrap_input(__method__, field, options) { |opts| file_field(field, opts) } end
    def input_telephone(field, options = {}); wrap_input(__method__, field, options) { |opts| telephone_field(field, opts) } end
    def input_text_area(field, options = {}); wrap_input(__method__, field, options) { |opts| text_area(field, opts) } end
    def input_check_box(field, options = {}); wrap_input(__method__, field, options) { |opts| check_box(field, opts) } end

    def input_hidden(field, options = {}); hidden_field(field, options) end

    def input_check_box_inline(field, options = {})
      wrap_input(__method__, field, options, label_last: true) do |opts|
        check_box(field, opts)
      end
    end

    def input_select(field, collection, options = {}, html_options = {})
      wrap_input(__method__, field, html_options) do |opts|
        select(field, collection, options, opts)
      end
    end

    def show_base_errors
      return if @object.base_errors.empty?

      tag.div class: ActiveDryForm.config.css_classes.base_error do
        tag.ul do
          # внутри ошибки может быть html
          @object.base_errors.map { tag.li _1.html_safe }.join.html_safe
        end
      end
    end

    def show_error(field)
      ActiveDryForm::Input.new(self, __method__, field, {}).error_text
    end

    def button(value = nil, options = {}, &block)
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

    ARRAY_NULL = %w[null].freeze
    private def input_type(field)
      (Array.wrap(object.info(field)[:type]) - ARRAY_NULL).first
    end

    private def wrap_input(method_type, field, options, wrapper_options = {})
      config = ActiveDryForm.config.html_options._settings[method_type] ? ActiveDryForm.config.html_options[method_type] : EMPTY_HASH
      options = config.merge(options)

      options[:class] = Array.wrap(config[:class]) + Array.wrap(options[:class]) if config[:class]
      options[:required] = object.info(field)[:required] unless options.key?(:required)

      Input
        .new(self, method_type, field, options)
        .wrap_tag(yield(options), **wrapper_options)
    end

  end
end
