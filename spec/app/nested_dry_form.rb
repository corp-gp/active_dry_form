# frozen_string_literal: true

class NestedDryForm < ActiveDryForm::Form

  class PersonalInfoForm < ActiveDryForm::Form

    fields(:personal_info) do
      params do
        required(:age).filled(:integer, gteq?: 18)
        optional(:id).maybe(:integer)
        optional(:date_of_birth).maybe(:date, gt?: Date.new(1950), lt?: Date.new(2010))
      end
    end

  end

  class BookmarkForm < ActiveDryForm::Form

    fields(:bookmark) do
      params do
        required(:url).filled(:string)
        optional(:id).maybe(:integer)
        optional(:name).maybe(:string)
      end
    end

  end

  fields(:user) do
    params do
      optional(:name).maybe(:string)
      optional(:bookmarks).array(Dry.Types::Instance(BookmarkForm))
      optional(:personal_info).value(Dry.Types::Instance(PersonalInfoForm))
    end
  end

  action def update
    bookmarks_data = data.delete(:bookmarks).compact
    personal_info_data = data.delete(:personal_info)

    record.attributes = data
    record.bookmarks_attributes = bookmarks_data
    record.personal_info_attributes = personal_info_data
    record.save!

    Success(record)
  end

end
