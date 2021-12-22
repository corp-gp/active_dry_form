# frozen_string_literal: true

module ActiveDryForm
  class BaseForm

    attr_reader :params, :record, :errors

    def initialize(params, record, errors)
      @params = params || {}
      @record = record
      @errors = errors || {}
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
          define_method nested_namespace do
            sub_klass.new(params[nested_namespace], record.try(nested_namespace), errors[nested_namespace])
          end
        elsif value[:member]
          define_method nested_namespace do
            (record.try(nested_namespace) || []).map.with_index do |associated_record, idx|
              sub_klass.new(params.dig(nested_namespace, idx), associated_record, errors.dig(nested_namespace, idx))
            end
          end
        else
          define_method key do
            params[key] || record.try(key)
          end
        end
      end
    end

  end
end
