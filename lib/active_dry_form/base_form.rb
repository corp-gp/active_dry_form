# frozen_string_literal: true

module ActiveDryForm
  class BaseForm

    attr_reader :params, :record, :errors

    def initialize(record: nil, params: nil, errors: {})
      @params = {}
      @record = record
      @errors = errors

      self.attributes = params if params
    end

    def persisted?
      record&.persisted?
    end

    def model_name
      self.class::NAMESPACE
    end

    def info(sub_key)
      self.class::FIELDS_INFO[sub_key]
    end

    # ActionView::Helpers::Tags::Translator#human_attribute_name
    def to_model
      self
    end

    def to_key
      key = record&.id
      [key] if key
    end

    # hidden field for nested association
    def id
      record&.id
    end

    # используется при генерации URL, когда record.persisted?
    def to_param
      record.id.to_s
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
      self::FIELDS_INFO.each do |key, value|
        nested_namespace =
          if value[:keys] || value[:member]
            key
          end

        if nested_namespace
          sub_klass = Class.new(BaseForm)
          sub_klass.const_set :NAMESPACE, ActiveModel::Name.new(nil, nil, nested_namespace.to_s)
          sub_klass.const_set :FIELDS_INFO, value[:keys] || value[:member][:keys]
          sub_klass.define_methods
        end

        if value[:keys]
          define_method "#{nested_namespace}=" do |nested_params|
            @params[nested_namespace] = sub_klass.new(record: record.try(nested_namespace), params: nested_params)
          end
          define_method nested_namespace do
            if @params.key?(nested_namespace)
              @params[nested_namespace]
            else
              sub_klass.new(record: record.try(nested_namespace), errors: errors[nested_namespace])
            end
          end
        elsif value[:member]
          define_method "#{nested_namespace}=" do |nested_params|
            records = record.try(nested_namespace) || []
            @params[nested_namespace] = nested_params.map.with_index { |v, idx| sub_klass.new(params: v, record: records[idx]) }
          end
          define_method nested_namespace do
            if @params.key?(nested_namespace)
              @params[nested_namespace]
            else
              (record.try(nested_namespace) || []).map.with_index { |r, idx| sub_klass.new(record: r, errors: errors.dig(nested_namespace, idx)) }
            end
          end
        else
          define_method "#{key}=" do |v|
            @params[key] = _deep_transform_values_in_params!(v)
          end
          define_method key do
            if @params.key?(key)
              @params[key]
            else
              record.try(key)
            end
          end
        end
      end
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

  end
end
