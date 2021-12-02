require "dry/schema/extensions/info/schema_compiler"

require "dry/schema/constants"

module Dry
  module Schema
    module Info
      class SchemaCompiler
        def visit_not(_node, opts = {})
          key = opts[:key]
          keys[key][:nullable] = true
        end

        def visit_predicate(node, opts = {})
          name, rest = node

          key = opts[:key]

          if name.equal?(:key?)
            keys[rest[0][1]] = { required: opts.fetch(:required, true) }
          elsif name.equal?(:array?)
            keys[key][:array] = true
          else
            type = PREDICATE_TO_TYPE[name]
            keys[key][:type] = type if type
          end
        end
      end
    end
  end
end