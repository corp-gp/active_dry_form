# frozen_string_literal: true

class NestedHasOneForm < ActiveDryForm::Form

  fields(:user) do
    params do
      optional(:name).maybe(:string)

      optional(:personal_info).hash do
        required(:age).filled(:integer)
        optional(:date_of_birth).maybe(:date, gt?: Date.new(1950), lt?: Date.new(2010))
      end

      optional(:dimensions).hash do
        required(:height).filled(:integer)
        optional(:weight).filled(:integer)
      end
    end
  end

  action def update
    record.attributes = validator.to_h.except(:personal_info)
    record.personal_info_attributes = validator[:personal_info] if validator[:personal_info]
    record.save!
    Success(record)
  end

end
