# frozen_string_literal: true

class FieldVarietyForm < ActiveDryForm::Form

  fields(:user) do
    params do
      optional(:id).maybe(:integer)
      optional(:name).maybe(:string)
      optional(:age).maybe(:integer)
      optional(:is_retail).maybe(:bool)
      optional(:password).maybe(:string)
      optional(:email).maybe(:string)
      optional(:phone).maybe(:string)
      optional(:url).maybe(:string)
      optional(:about).maybe(:string)
      optional(:birthday).maybe(:date)
      optional(:call_on).maybe(:time)
      optional(:run_at).maybe(:date_time)
    end
  end

end
