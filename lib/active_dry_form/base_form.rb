# frozen_string_literal: true

module ActiveDryForm
  class BaseForm

    attr_reader :record
    attr_writer :errors

    def initialize(params: nil)
      self.attributes = params if params
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

    def attributes=(hsh)
      hsh.each do |attr, v|
        next if !ActiveDryForm.config.strict_param_keys && !respond_to?("#{attr}=")

        public_send("#{attr}=", v)
      end
    end

    def attributes
      _deep_extract_attributes(self)
    end

    def self.human_attribute_name(field)
      I18n.t(field, scope: :"activerecord.attributes.#{self::NAMESPACE.i18n_key}")
    end

    def self.define_methods
      self::FIELDS_INFO[:properties].each do |key, value|
        nested_namespace = key if value[:properties] || value.dig(:items, :properties)

        if nested_namespace
          sub_klass = Class.new(BaseForm)
          sub_klass.const_set :NAMESPACE, ActiveModel::Name.new(nil, nil, nested_namespace.to_s)
          sub_klass.const_set :FIELDS_INFO, value[:items] || value
          sub_klass.define_methods
        end

        if nested_namespace && value[:type] == 'object'
          define_method "#{nested_namespace}=" do |nested_params|
            params[nested_namespace] = sub_klass.new(params: nested_params)
          end
          define_method nested_namespace do
            params[nested_namespace] ||= sub_klass.new
            params[nested_namespace].record = record.try(nested_namespace)
            params[nested_namespace].errors = errors[nested_namespace]
            params[nested_namespace]
          end
        elsif nested_namespace && value[:type] == 'array'
          define_method "#{nested_namespace}=" do |nested_params|
            params[nested_namespace] = NestedFormList.new(nested_params.map { |item_params| sub_klass.new(params: item_params) })
            params[nested_namespace].form_class = sub_klass
            params[nested_namespace]
          end
          define_method nested_namespace do
            params[nested_namespace] ||= NestedFormList.new
            params[nested_namespace].form_class = sub_klass
            (record.try(nested_namespace) || []).map.with_index do |nested_record, idx|
              params[nested_namespace][idx].record = nested_record
              params[nested_namespace][idx].errors = errors.dig(nested_namespace, idx)
            end
            params[nested_namespace]
          end
        else
          define_method "#{key}=" do |v|
            params[key] = _deep_transform_values_in_params!(v)
          end
          define_method key do
            if params.key?(key)
              params[key]
            else
              record.try(key)
            end
          end
        end
      end
    end

    def params
      @params ||= {}
    end

    def errors
      @errors ||= {}
    end

    private def _deep_transform_values_in_params!(object)
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

    private def _deep_extract_attributes(object)
      case object
      when BaseForm
        object.params.transform_values { |v| _deep_extract_attributes(v) }
      when Hash
        object.transform_values { |v| _deep_extract_attributes(v) }
      when Array
        object.map { |v| _deep_extract_attributes(v) }
      else
        object
      end
    end

    class NestedFormList < Array

      attr_accessor :form_class

      def [](idx)
        super || public_send(:[]=, idx, form_class.new) # default form object
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
