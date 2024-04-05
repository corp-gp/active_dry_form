# frozen_string_literal: true

require_relative 'application_record'

class User < ApplicationRecord

  has_one :personal_info, class_name: 'PersonalInfo'
  accepts_nested_attributes_for :personal_info

  has_many :bookmarks
  accepts_nested_attributes_for :bookmarks

  serialize :favorites, JSON
  serialize :dimensions, JSON

end
