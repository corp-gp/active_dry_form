# frozen_string_literal: true

class LooseJsonSchemaForm < ActiveDryForm::Form

  BOOKMARK =
    Dry::Schema.Params do
      required(:url).filled(:string, format?: /^https?:/)
    end

  fields(:user) do
    params do
      required(:personal_info).hash do
        required(:email).value(:string, format?: /@/)
      end
      required(:bookmarks).array(BOOKMARK)
      required(:settings).value(Dry::Types['strict.hash'].constructor(&:compact))
    end
  end

end
