# frozen_string_literal: true

module ActiveDryForm
  class Builder

    def input_custom(field, options = {})
      wrap_input(__method__, field, options) do |opts|
        text_field(field, opts)
      end
    end

  end
end
