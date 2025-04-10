# frozen_string_literal: true

require_relative 'application_form'

class CompositePrimaryKeyForm < ApplicationForm

  fields(:product_user) do
    params do
      required(:state).filled(:string)
    end
  end

end
