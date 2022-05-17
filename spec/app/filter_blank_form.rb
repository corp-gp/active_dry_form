# frozen_string_literal: true

class FilterBlankForm < ActiveDryForm::Form

  NESTED_FIELDS =
    Dry::Schema.Params do
      required(:ids).array(:integer)
    end

  fields(:form) do
    params do
      optional(:name).maybe(:string)
      required(:ids).array(:integer)

      required(:nested_one).hash(NESTED_FIELDS)
      required(:nested_many).array(NESTED_FIELDS)
    end
  end

end
