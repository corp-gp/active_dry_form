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

    def self.action(method)
      alias_method :"__#{method}", method

      class_eval <<~RUBY, __FILE__, __LINE__ + 1 # rubocop:disable Style/DocumentDynamicEvalDefinition
        def #{method}(...)
          validate
          return Failure(:validate_invalid) unless valid?

          result = __#{method}(...)

          unless result.is_a?(::Dry::Monads::Result)
            raise ResultError, 'method `#{method}` must return `monad`'
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

  end
end
