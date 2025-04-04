# frozen_string_literal: true

require_relative 'application_record'

class ProductUser < ApplicationRecord

  self.primary_key = %i[product_id user_id]

end
