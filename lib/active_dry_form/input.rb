# frozen_string_literal: true

module ActiveDryForm
  class Input

    def initialize(builder, method_type, method, options)
      @builder = builder
      @method_type = method_type
      @method = method

      info = builder.object.info(method)
      if info.nil?
        raise ArgumentError, "Field #{method} is not found. Check form definition"
      end

      @dry_type = (Array(info[:type]) - %w[null]).first

      @label_opts = options[:label]
      @label_text = options[:label_text]
      @hint_text = options[:hint]
      @input_user_options = options.except(:label, :hint, :label_text)

      @required = info[:required] || @input_user_options[:required]
      @input_user_options[:required] = true if @required
    end

    def css_classes
      [
        'input',
        @method_type,
        @dry_type,
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

      @builder.tag.div obj_error_text.join('<br />').html_safe, class: ActiveDryForm.config.error_class
    end

    def error?(method)
      @builder.object.errors.key?(method)
    end

    def input_type
      @input_type ||=
        case @dry_type
        when 'date', 'boolean' then @dry_type.to_sym
        when 'time' then :datetime
        when 'date-time' then raise 'use :time instead :date_time (does not apply time zone) in params block'
        when 'integer', 'number' then :number
        else
          case @method.to_s
          when /password/ then :password
          when /email/    then :email
          when /phone/    then :telephone
          when /url/      then :url
          else :text
          end
        end
    end

    def input_options
      @input_options ||=
        begin
          defaults = ActiveDryForm.config.default_html_options[@method_type]
          defaults = defaults[input_type] if @method_type == :input
          defaults.merge(@input_user_options) do |_key, oldval, newval|
            Array.wrap(oldval) + Array.wrap(newval)
          end
        end
    end

  end
end
