# frozen_string_literal: true

module ActiveDryForm
  class BaseForm

    attr_accessor :data, :parent_form, :errors, :base_errors
    attr_reader :record, :validator, :attributes

    def initialize(record: nil, params: nil)
      @attributes = {}

      self.params = params if params
      self.record = record if record

      @errors = {}
      @base_errors = []
    end

    def errors_full_messages
      return if errors.blank?

      errors.flat_map do |field, errors|
        case errors
        when Array
          "#{t(model_name.i18n_key, field)}: #{errors.join(',')}"
        when Hash
          errors.map do |k, v|
            case k
            when Integer
              nested_key, nested_errors = v.to_a.first
              "#{t(field, nested_key)} (#{k + 1}): #{nested_errors.join(',')}"
            when Symbol
              "#{t(field, k)}: #{v.join(',')}"
            end
          end
        end
      end
    end

    def t(*keys)
      str_keys = keys.join('.')
      I18n.t("helpers.label.#{str_keys}", default: :"activerecord.attributes.#{str_keys}")
    end

    def persisted?
      record&.persisted?
    end

    def model_name
      self.class::NAMESPACE
    end

    def info(sub_key)
      {
        type:     self.class::FIELDS_INFO.dig(:properties, sub_key, :format) || self.class::FIELDS_INFO.dig(:properties, sub_key, :type),
        required: self.class::FIELDS_INFO[:required].include?(sub_key.to_s),
      }
    end

    # ActionView::Helpers::Tags::Translator#human_attribute_name
    def to_model
      self
    end

    def to_key
      key = id
      [key] if key
    end

    # hidden field for nested association
    def id
      record&.id
    end

    # используется при генерации URL, когда record.persisted?
    def to_param
      id.to_s
    end

    def record=(value)
      @record =
        if value.is_a?(Hash)
          hr = HashRecord.new
          hr.replace(value)
          hr.define_methods
          hr
        else
          value
        end
    end

    def params=(params)
      param_key = self.class::NAMESPACE.param_key
      form_params = params[param_key] || params[param_key.to_sym] || params

      if form_params.is_a?(::ActionController::Parameters)
        unless ActiveDryForm.config.allow_action_controller_params
          message = 'in `params` use `request.parameters` instead of `params` or set `allow_action_controller_params` to `true` in config'
          raise ParamsNotAllowedError, message
        end

        form_params = form_params.to_unsafe_h
      end

      self.attributes = form_params
    end

    def attributes=(attrs)
      attrs.each do |attr, v|
        next if !ActiveDryForm.config.strict_param_keys && !respond_to?(:"#{attr}=")

        public_send(:"#{attr}=", v)
      end
    end

    def validate
      @validator   = self.class::CURRENT_CONTRACT.call(attributes, { form: self, record: record })
      @data        = @validator.values.data
      @errors      = @validator.errors.to_h
      @base_errors = @validator.errors.filter(:base?).map(&:to_s)

      @is_valid = @base_errors.empty? && @errors.empty?

      _deep_validate_nested
    end

    def valid?
      @is_valid
    end

    def self.human_attribute_name(field)
      I18n.t(field, scope: :"activerecord.attributes.#{self::NAMESPACE.i18n_key}")
    end

    def self.wrap(object)
      return object if object.is_a?(BaseForm)

      form = new
      form.attributes = object if object
      form
    end

    def self.define_methods
      const_set :NESTED_FORM_KEYS, []

      self::FIELDS_INFO[:properties].each do |key, value|
        define_method :"#{key}=" do |v|
          attributes[key] = _deep_transform_values_in_params!(v)
        end

        define_method :'[]=' do |k, v|
          attributes[k] = _deep_transform_values_in_params!(v)
        end

        sub_klass =
          if value[:properties] || value.dig(:items, :properties)
            Class.new(BaseForm).tap do |klass|
              klass.const_set :NAMESPACE, ActiveModel::Name.new(nil, nil, key.to_s)
              klass.const_set :FIELDS_INFO, value[:items] || value
              klass.define_methods
            end
          elsif const_defined?(:CURRENT_CONTRACT)
            dry_type = self::CURRENT_CONTRACT.schema.schema_dsl.types[key]
            dry_type = dry_type.member if dry_type.respond_to?(:member)
            dry_type.primitive if dry_type.respond_to?(:primitive)
          end

        if sub_klass && sub_klass < BaseForm
          self::NESTED_FORM_KEYS << {
            type:      sub_klass.const_defined?(:CURRENT_CONTRACT) ? :instance : :hash,
            namespace: key,
            is_array:  value[:type] == 'array',
          }
          nested_key = key
        end

        if nested_key && value[:type] == 'array'
          define_method nested_key do
            nested_records = record.try(nested_key) || []
            if attributes.key?(nested_key)
              attributes[nested_key].each_with_index do |nested_params, idx|
                attributes[nested_key][idx] = sub_klass.wrap(nested_params)
                attributes[nested_key][idx].record = nested_records[idx]
                attributes[nested_key][idx].parent_form = self
                attributes[nested_key][idx]
              end
            else
              attributes[nested_key] =
                nested_records.map do |nested_record|
                  nested_form = sub_klass.new
                  nested_form.record = nested_record
                  nested_form.parent_form = self
                  nested_form
                end
            end
            attributes[nested_key]
          end
        elsif nested_key
          define_method nested_key do
            attributes[nested_key] = sub_klass.wrap(attributes[nested_key])
            attributes[nested_key].record = record.try(nested_key)
            attributes[nested_key].parent_form = self
            attributes[nested_key]
          end
        else
          define_method key do
            (data || attributes).fetch(key) { record.try(key) }
          end
        end
      end
    end

    private def _deep_transform_values_in_params!(object)
      return object if object.is_a?(BaseForm)

      case object
      when String
        object.strip.presence
      when Hash
        object.transform_values! { |value| _deep_transform_values_in_params!(value) }
      when Array
        object.map! { |e| _deep_transform_values_in_params!(e) }
        object.compact!
        object
      else
        object
      end
    end

    private def _deep_validate_nested
      self.class::NESTED_FORM_KEYS.each do |nested_info|
        namespace, type, is_array = nested_info.values_at(:namespace, :type, :is_array)
        next unless attributes.key?(namespace)

        nested_data = public_send(namespace)

        if type == :hash && is_array
          nested_data.each_with_index do |nested_form, idx|
            nested_form.errors = @errors.dig(namespace, idx) || {}
            nested_form.data   = @data.dig(namespace, idx)
          end
        elsif type == :hash
          nested_data.errors = @errors[namespace] || {}
          nested_data.data   = @data[namespace]
        elsif type == :instance && is_array
          @data[namespace] = []
          nested_data.each_with_index do |nested_form, idx|
            nested_form.validate
            @data[namespace][idx] = nested_form.data
            @base_errors += nested_form.base_errors
            @is_valid &= nested_form.valid?
          end
        else
          nested_data.validate
          @data[namespace] = nested_data.data
          @base_errors += nested_data.base_errors
          @is_valid &= nested_data.valid?
        end
      end
    end

    class HashRecord < Hash

      def persisted?
        false
      end

      def id
        self[:id] || self['id']
      end

      def define_methods
        keys.each do |key|
          define_singleton_method(key) { fetch(key) }
        end
      end

    end

  end
end
