# frozen_string_literal: true

class BaseValidationForm < UserForm

  fields(:user) do
    params do
      optional(:name).maybe(:string)
    end

    rule do |context:|
      base.failure('user is read only') if context[:form].record.persisted?
    end
  end

end
