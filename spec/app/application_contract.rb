# frozen_string_literal: true

class ApplicationContract < ActiveDryForm::BaseContract

  def self.rule_latin(field)
    rule(field) do
      key.failure('non-latin symbols detected') if /[^a-z]+/i.match?(value)
    end
  end

end
