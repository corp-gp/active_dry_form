# frozen_string_literal: true

class NestedHasManyForm < ActiveDryForm::Form

  BOOKMARK =
    Dry::Schema.Params do
      required(:url).filled(:string)
      optional(:id).maybe(:integer)
      optional(:name).maybe(:string)
    end

  FAVORITE =
    Dry::Schema.Params do
      required(:kind).filled(:string)
      optional(:name).maybe(:string)
    end

  fields(:user) do
    params do
      optional(:name).maybe(:string)
      optional(:bookmarks).array(BOOKMARK)
      optional(:favorites).array(FAVORITE)
    end
  end

  action def update
    record.attributes = validator.to_h.except(:bookmarks)
    record.bookmarks_attributes = validator[:bookmarks] if validator[:bookmarks]
    record.save!
    Success(record)
  end

end
