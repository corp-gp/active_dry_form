# frozen_string_literal: true

class DefaultCreateForm < ActiveDryForm::Form

  fields(:user) do
    params do
      required(:name).filled(:string)
    end
  end

  default def create_default
    { name: 'Vasya' }
  end

end
