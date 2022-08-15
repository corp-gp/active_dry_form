# frozen_string_literal: true

class UserForm < ActiveDryForm::Form

  fields(:user) do
    params do
      required(:name).filled(:string)
      optional(:second_name).maybe(:string)
    end
  end

  action def create
    record = User.create!(data)
    Success(record)
  end

  action def update
    record.update!(data)
    Success(record)
  end

end
