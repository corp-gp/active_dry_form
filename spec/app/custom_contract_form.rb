# frozen_string_literal: true

require_relative 'application_form'

class CustomContractForm < ApplicationForm

  fields(:user) do
    params do
      required(:name).filled(:string)
    end

    rule_latin :name
  end

  action def create
    record = User.create!(data)
    Success(record)
  end

end
