# frozen_string_literal: true

module ActiveDryForm
  class BaseForm < Hash

    attr_reader :record, :validator, :data, :base_errors, :errors

    attr_writer :errors

    def initialize(record: nil, params: nil)
      self.params = params if params
      self.record = record if record
      @errors = {}
      @base_errors = []
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
      form_params = params[param_key] || params[param_key.to_sym]
      raise ArgumentError, "key '#{param_key}' not found in params" if form_params.nil?

      self.attributes = form_params
    end

    def attributes=(attrs)
      if attrs.is_a?(::ActionController::Parameters)
        unless ActiveDryForm.config.allow_action_controller_params
          message = 'in `params` use `request.parameters` instead of `params` or set `allow_action_controller_params` to `true` in config'
          raise ParamsNotAllowedError, message
        end

        attrs = attrs.to_unsafe_h
      end

      attrs.each do |attr, v|
        next if !ActiveDryForm.config.strict_param_keys && !respond_to?("#{attr}=")

        public_send("#{attr}=", v)
      end
    end

    def attributes
      self
    end

    def validate
      @errors = {}
      @base_errors = []

      nested_validate

      @validator = self.class::CURRENT_CONTRACT.call(attributes, { form: self, record: record })
      @data      = @validator.values.data

      @errors.merge!(@validator.errors.to_h)

      if @validator.failure?
        @base_errors += @validator.errors.filter(:base?).map(&:to_s)
      end

      @is_valid = @base_errors.empty? && @errors.empty?
    end

    private def nested_validate
      each_key do |key|
        nested_value = public_send(key)

        if nested_value.is_a?(BaseForm) && nested_value.class.has_contract?
          nested_value.validate
          unless nested_value.valid?
            @errors[key] = nested_value.errors
            @base_errors += nested_value.base_errors
          end
        elsif nested_value.is_a?(Array)
          nested_value.each_with_index do |nested_list_value, idx|
            if nested_list_value.is_a?(BaseForm)&& nested_list_value.class.has_contract?
              nested_list_value.validate
              unless nested_list_value.valid?
                @errors[key] ||= {}
                @errors[key][idx] = nested_list_value.errors
                @base_errors += nested_list_value.base_errors
              end
            end
          end
        end
      end
    end

    def valid?
      @is_valid
    end

    def self.contract
      self::CURRENT_CONTRACT
    end

    def self.has_contract?
      const_defined?(:CURRENT_CONTRACT)
    end

    def self.human_attribute_name(field)
      I18n.t(field, scope: :"activerecord.attributes.#{self::NAMESPACE.i18n_key}")
    end

    # @private internal api
    def self.wrap(object)
      return object if object.is_a?(BaseForm)

      form = new
      form.attributes = object if object
      form
    end

    # @private internal api
    def self.define_methods
      self::FIELDS_INFO[:properties].each do |key, value|
        nested_namespace = key if value[:properties] || value.dig(:items, :properties)

        nested_type =
          if value[:type] == 'object'
            contract.schema.schema_dsl.types[key].type.primitive
          elsif value.dig(:items, :type) == 'object'
            contract.schema.schema_dsl.types[key].type.member.type.primitive
          end

        if nested_type&.< BaseForm
          sub_klass = nested_type
          nested_namespace = key
        elsif nested_namespace
          sub_klass = Class.new(BaseForm)
          sub_klass.const_set :NAMESPACE, ActiveModel::Name.new(nil, nil, nested_namespace.to_s)
          sub_klass.const_set :FIELDS_INFO, value[:items] || value
          sub_klass.define_methods
        end

        define_method "#{key}=" do |v|
          self[key] = _deep_transform_values_in_params!(v)
        end

        if nested_namespace && value[:type] == 'object'
          define_method nested_namespace do
            self[nested_namespace] = sub_klass.wrap(@data&.dig(nested_namespace) || self[nested_namespace])
            self[nested_namespace].record = record.try(nested_namespace)
            self[nested_namespace].errors = errors[nested_namespace] if errors.key?(nested_namespace)
            self[nested_namespace]
          end
        elsif nested_namespace && value[:type] == 'array'
          define_method nested_namespace do
            nested_records = record.try(nested_namespace) || []
            if key?(nested_namespace)
              (@data&.dig(nested_namespace) || self[nested_namespace]).each_with_index do |nested_params, idx|
                self[nested_namespace][idx] = sub_klass.wrap(nested_params)
                self[nested_namespace][idx].record = nested_records[idx]
                self[nested_namespace][idx].errors = errors.dig(nested_namespace, idx) if errors.dig(nested_namespace, idx)
                self[nested_namespace][idx]
              end
            else
              self[nested_namespace] =
                nested_records.map do |nested_record|
                  nested_form = sub_klass.new
                  nested_form.record = nested_record
                  nested_form
                end
            end
            self[nested_namespace]
          end
        else
          define_method key do
            (@data || self).fetch(key) { record.try(key) }
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
