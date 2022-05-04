# frozen_string_literal: true

require_relative 'application_contract'

class ApplicationForm < ActiveDryForm::Form

  self.contract_klass = ApplicationContract

end
