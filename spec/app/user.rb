# frozen_string_literal: true

require_relative 'application_record'

class User < ApplicationRecord

  has_one :personal_info
  accepts_nested_attributes_for :personal_info

  has_many :bookmarks
  accepts_nested_attributes_for :bookmarks

  serialize :favorites, coder: JSON
  serialize :dimensions, coder: JSON

end
