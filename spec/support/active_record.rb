# frozen_string_literal: true

require 'active_record'

RSpec.configure do |config|
  config.before(:all) do
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
    ActiveRecord::Migration.verbose = false

    ActiveRecord::Schema.define do
      create_table(:users, force: true) do |t|
        t.string :name
        t.string :second_name
      end
      create_table(:bookmarks, force: true) do |t|
        t.integer :user_id
        t.string :url
        t.string :name
      end
      create_table(:personal_infos, force: true) do |t|
        t.integer :user_id
        t.integer :age
        t.date :date_of_birth
      end
    end
  end

  config.after(:all) do
    ActiveRecord::Base.remove_connection
  end
end
