# frozen_string_literal: true

module ActiveDryForm
  class Input

    attr_reader :input_opts, :input_type

    def initialize(builder, method_type, method, options)
      @builder = builder
      @method_type = method_type
      @method = method

      info = builder.object.info(method)
      if info.nil?
        raise ArgumentError, "Field #{method} is not found. Check form definition"
      end

      @input_type = info[:type]
      @required = info[:required]

      @label_opts = options[:label]
      @label_text = options[:label_text]
      @hint_text = options[:hint]
      @input_opts = options.except(:label, :hint, :label_text)
      @input_opts[:required] = true if @required
    end

    def css_classes
      [
        'input',
        @method_type,
        @input_type,
        @method,
        ('required' if @required),
        ('error' if error?(@method)),
      ].compact
    end

    def wrap_tag(input, label_last: nil)
      @builder.tag.div class: css_classes do
        [
          label_last ? input : label,
          label_last ? label : input,
          hint_text,
          error_text,
        ].compact.join.html_safe
      end
    end

    def label
      @builder.label(@method, @label_text) unless @label_opts == false
    end

    def hint_text
      return unless @hint_text

      @builder.tag.small @hint_text, class: 'help-text'
    end

    def error_text
      return unless error?(@method)

      obj_error_text =
        case e = @builder.object.errors[@method]
        when Hash then e.values
        else e
        end

      @builder.tag.div obj_error_text.join('<br />').html_safe, class: 'form-error is-visible'
    end

    def error?(method)
      @builder.object.errors.key?(method)
    end

  end
end
