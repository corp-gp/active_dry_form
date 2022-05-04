# frozen_string_literal: true

class DefaultCreateForm < ActiveDryForm::Form

  fields(:user) do
    params do
      required(:name).filled(:string)
    end
  end

  def create_default
    self.name = 'Vasya'
  end

end
