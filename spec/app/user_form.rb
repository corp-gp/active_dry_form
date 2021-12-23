# frozen_string_literal: true

class UserForm < ActiveDryForm::Form

  fields(:user) do
    params do
      required(:name).filled(:string)
    end
  end

  action def create
    record = User.create!(validator.to_h)
    Success(record)
  end

  action def update
    record.update!(validator.to_h)
    Success(record)
  end

end
