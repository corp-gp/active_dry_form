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

      class_eval <<~RUBY, __FILE__, __LINE__ + 1
        # def create(...)
        #   if validator.failure?
        #     @base_errors = validator.errors.filter(:base?).map(&:to_s).presence
        #     return Failure(:validate_invalid)
        #   end
        #
        #   result = __create(...)
        #
        #   unless result.is_a?(::Dry::Monads::Result)
        #     raise ResultError, 'method `create` should be returning `monad`'
        #   end
        #
        #   case result
        #   in Failure[:failure_service, base_errors]
        #     @base_errors = base_errors
        #   else
        #   end
        #
        #   result
        # end

        def #{method}(...)
          if validator.failure?
            @base_errors = validator.errors.filter(:base?).map(&:to_s).presence
            return Failure(:validate_invalid)
          end

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

    attr_reader :base_errors

    def initialize(record: nil, params: nil)
      raise 'in `params` use `request.parameters` instead of `params`' if params.is_a?(::ActionController::Parameters)

      if params
        param_key = self.class::NAMESPACE.param_key
        form_params = params[param_key] || params[param_key.to_sym]
        raise ArgumentError, "key '#{param_key}' not found in params" if form_params.nil?

        self.attributes = form_params
      end

      @record = record
    end

    def validator
      @validator ||= self.class::CURRENT_CONTRACT.call(attributes, { form: self, record: record })
    end

    def errors
      return {} unless @validator

      @errors ||= @validator.errors.to_h
    end

    def view_component
      self.class.module_parent::Component.new(self)
    end

  end
end
