# frozen_string_literal: true

require 'dry-monads'
require 'dry-validation'
require 'active_model'
require 'action_view'
require 'action_controller'

require_relative 'active_dry_form/version'
require_relative 'active_dry_form/schema_compiler_patch'
require_relative 'active_dry_form/builder'
require_relative 'active_dry_form/base_form'
require_relative 'active_dry_form/form'
require_relative 'active_dry_form/input'
require_relative 'active_dry_form/form_helper'

module ActiveDryForm
  class Error < StandardError; end
  # Your code goes here...
end
