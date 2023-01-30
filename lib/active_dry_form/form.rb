# frozen_string_literal: true

module ActiveDryForm
  class Form < BaseForm

    include Dry::Monads[:result]
    Dry::Schema.load_extensions(:json_schema)
    ResultError = Class.new(StandardError)

    cattr_accessor :contract_klass, instance_accessor: false, default: ::ActiveDryForm::BaseContract

    def self.fields(namespace, &block)
      const_set :NAMESPACE, ActiveModel::Name.new(nil, nil, namespace.to_s)
      const_set :CURRENT_CONTRACT, Class.new(contract_klass, &block).new
      const_set :FIELDS_INFO, self::CURRENT_CONTRACT.schema.json_schema(loose: true)

      define_methods
    end

    attr_reader :validator, :data, :errors, :base_errors

    def self.action(method)
      alias_method :"__#{method}", method

      class_eval <<~RUBY, __FILE__, __LINE__ + 1 # rubocop:disable Style/DocumentDynamicEvalDefinition
        def #{method}(...)
          validate
          return Failure(:validate_invalid) unless valid?

          result = __#{method}(...)

          unless result.is_a?(::Dry::Monads::Result)
            raise ResultError, 'method `#{method}` should be returning `monad`'
          end

          case result
          in Failure[:failure_service, base_errors]
            @base_errors = base_errors
          else
          end

          result
        end
      RUBY
    end

    def initialize(record: nil, params: nil)
      if params
        param_key = self.class::NAMESPACE.param_key
        form_params = params[param_key] || params[param_key.to_sym]
        raise ArgumentError, "key '#{param_key}' not found in params" if form_params.nil?

        self.attributes = form_params
      end

      @errors = {}
      @record = record
    end

    def validate
      @validator = self.class::CURRENT_CONTRACT.call(attributes, { form: self, record: record })
      @data      = @validator.values.data
      @errors    = @validator.errors.to_h
      @is_valid  = @validator.success?

      if @validator.failure?
        @base_errors = @validator.errors.filter(:base?).map(&:to_s).presence
      end
    end

    def valid?
      @is_valid
    end

  end
end
