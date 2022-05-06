# frozen_string_literal: true

module ActiveDryForm
  class Form < BaseForm

    include Dry::Monads[:result]
    Dry::Schema.load_extensions(:info)
    ResultError = Class.new(StandardError)

    cattr_accessor :contract_klass, instance_accessor: false, default: ::ActiveDryForm::BaseContract

    def self.fields(namespace, &block)
      const_set :NAMESPACE, ActiveModel::Name.new(nil, nil, namespace.to_s)
      const_set :CURRENT_CONTRACT, Class.new(contract_klass, &block).new
      const_set :FIELDS_INFO, self::CURRENT_CONTRACT.schema.info[:keys]

      define_methods
    end

    def self.default(method)
      alias_method :"__#{method}", method

      class_eval <<~RUBY, __FILE__, __LINE__ + 1
        # def create_default(...)
        #  @params.merge!(__create_default(...))
        # end

        def #{method}(...)
          @params.merge!(__#{method}(...))
        end
      RUBY
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

      @params =
        if params
          params.deep_transform_keys!(&:to_sym)
          param_key = self.class::NAMESPACE.param_key.to_sym
          raise "missing param '#{param_key}' in `params`" unless params.key?(param_key)

          _deep_transform_values_in_params!(params[param_key])
        else
          {}
        end

      @record = record
    end

    def validator
      @validator ||= self.class::CURRENT_CONTRACT.call(@params, { form: self, record: record })
    end

    def errors
      @errors ||= @validator ? @validator.errors.to_h : {}
    end

    def view_component
      self.class.module_parent::Component.new(self)
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

  end
end
