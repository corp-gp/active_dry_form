# frozen_string_literal: true

module ActiveDryForm
  class Form

    include Dry::Monads[:result]
    Dry::Schema.load_extensions(:info)
    ResultError = Class.new(StandardError)

    class ContractBase < Dry::Validation::Contract

      config.messages.load_paths << 'config/locales/dry_validation.ru.yml'
      config.messages.default_locale = :ru

    end

    def self.fields(namespace, &block)
      const_set :NAMESPACE, ActiveModel::Name.new(nil, nil, namespace.to_s)
      const_set :CURRENT_CONTRACT, Class.new(ContractBase, &block).new
      const_set :FIELDS_INFO, self::CURRENT_CONTRACT.schema.info[:keys]

      self::FIELDS_INFO.each do |key, value|
        if value[:keys]
          sub_klass = Class.new do
            const_set :NAMESPACE, ActiveModel::Name.new(nil, nil, key.to_s)
            const_set :FIELDS_INFO, value[:keys]

            def initialize(params, record, errors)
              @params = params || {}
              @record = record
              @errors = errors || {}
            end

            self::FIELDS_INFO.each_key do |sub_key|
              define_method sub_key do
                @params[sub_key] || @record.try(sub_key)
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

              def self.human_attribute_name(field)
                I18n.t(field, scope: :"activerecord.attributes.#{self::NAMESPACE.i18n_key}")
              end

              def errors
                @errors
              end
            end
          end
          define_method key do
            sub_klass.new(@params[key], @record.try(key), errors[key])
          end
        else
          define_method key do
            @params[key] || @record.try(key)
          end
        end
      end
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

    attr_reader :base_errors, :record

    def initialize(record: nil, params_form: nil, params_init: nil)
      raise 'in `params_form` use `request.parameters` instead of `params`' if params_form.is_a?(::ActionController::Parameters)
      raise 'in `params_init` use `request.parameters` instead of `params`' if params_init.is_a?(::ActionController::Parameters)

      @params =
        if params_form
          _deep_transform_values_in_params!(params_form[self.class::NAMESPACE.param_key].deep_transform_keys!(&:to_sym))
        elsif params_init
          params_init.deep_transform_keys!(&:to_sym)
        else
          {}
        end

      @record = record if record
    end

    def info(key)
      self.class::FIELDS_INFO[key]
    end

    def model_name
      self.class::NAMESPACE
    end

    # ActionView::Helpers::Tags::Translator#human_attribute_name
    def to_model
      self
    end

    def self.human_attribute_name(field)
      I18n.t(field, scope: :"activerecord.attributes.#{self::NAMESPACE.i18n_key}")
    end

    def persisted?
      @record&.persisted?
    end

    def to_key
      key = @record&.id
      [key] if key
    end

    # используется при генерации URL, когда record.persisted?
    def to_param
      @record.id.to_s
    end

    def validator
      @validator ||= self.class::CURRENT_CONTRACT.call(@params, { form: self })
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
