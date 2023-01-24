# frozen_string_literal: true

module ActiveDryForm
  class Input

    def initialize(builder, builder_method, field, options)
      @builder = builder
      @builder_method = builder_method
      @field = field

      @label_opts = options[:label]
      @label_text = options[:label_text]
      @hint_text = options[:hint]
      @required = options[:required]
      @input_user_options = options.except(:label, :hint, :label_text)
    end

    def css_classes
      [
        'input',
        @builder_method,
        ('required' if @required),
        ('error' if error?(@field)),
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
      @builder.label(@field, @label_text) unless @label_opts == false
    end

    def hint_text
      return unless @hint_text

      @builder.tag.small @hint_text, class: ActiveDryForm.config.css_classes.hint
    end

    def error_text
      return unless error?(@field)

      obj_error_text =
        case e = @builder.object.errors[@field]
        when Hash then e.values
        else e
        end

      @builder.tag.div obj_error_text.join('<br />').html_safe, class: ActiveDryForm.config.css_classes.error
    end

    def error?(field)
      @builder.object.errors.key?(field)
    end

  end
end
