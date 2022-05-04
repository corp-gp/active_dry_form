# frozen_string_literal: true

class NestedHasManyForm < ActiveDryForm::Form

  BOOKMARK =
    Dry::Schema.Params do
      required(:url).filled(:string)
      optional(:id).maybe(:integer)
      optional(:name).maybe(:string)
    end

  fields(:user) do
    params do
      optional(:name).maybe(:string)
      required(:bookmarks).array(BOOKMARK)
    end
  end

  action def update
    record.attributes = validator.to_h.except(:bookmarks)
    record.bookmarks_attributes = validator[:bookmarks]
    record.save!
    Success(record)
  end

end
