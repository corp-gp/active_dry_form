# ActiveDryForm

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/active_dry_form`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_dry_form'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install active_dry_form

## Usage

### General use case
#### View
##### app/components/admin/users/component.[slim, erb etc.]
```
active_dry_form_for [:user, form], url: component_path(form.persisted? ? :update : :create, id: form.record&.id),
html: { 'data-controller': 'users--create turbo-form', 'data-action': 'turbo-form#submit' } do |f|
  f.input :first_name
  f.input :last_name
  f.input :patronymic
  f.input :email
  f.input :phone
  f.input :birthday

  f.button

if form.persisted?
  link_to t('delete'), admin_users_path(form.record), method: :delete
```

#### Form class
##### app/components/admin/users/form.rb
```
module Admin
  module Users
    module Create
      class Form < ActiveDryForm::ApplicationForm

        fields :user do
          params do
            required(:first_name).filled(:string, min_size?: 2, max_size?: 100)
            required(:last_name).filled(:string, min_size?: 2, max_size?: 100)
            required(:gender).filled(included_in?: ::User::GENDERS)
            required(:phone).filled(Types::ValidPhone)

            optional(:email).maybe(Types::ValidEmail)
            optional(:patronymic).maybe(:string, min_size?: 2, max_size?: 100)
            optional(:birthday).maybe(:date, gt?: Date.new(1940, 1, 1), lt?: Time.zone.today - 10.years)
          end

          rule(:phone) do
            next unless value

            if ::User.where.not(confirmed_phone_at: nil).exists?(phone: value.normalized)
              key.failure(:duplicate)
            end
          end
        end

        action def create
          # Your user create code
          # do_something

          Success(user)
        end

        action def update
          record.update!(data)
          Success(record)
        end

        private def do_something
          # Do something code
        end

      end
    end
  end
end
```

#### Component controller
##### app/components/admin/users/controller.rb
```
module Admin
  module Users
    module Submit
      class Controller < Admin::AdminController

        def new
          render Form.new.view_component
        end

        def edit
          render Form.new(record: fetch_user).view_component
        end

        def create
          form = Form.new(params: request.parameters)

          case form.create
          in Success(_)
            render form.view_component
          else
            render form.view_component, status: :unprocessable_entity
          end
        end

        def update
          form = Form.new(record: fetch_user, params: request.parameters)

          case form.update
          in Success(_)
            redirect_to admin_users_path
          else
            render form.view_component, status: :unprocessable_entity
          end
        end

        private def fetch_user
          User.find(params[:id])
        end

      end
    end
  end
end
```

#### Component class
##### app/components/admin/users/component.rb
```
module Admin
  module Users
    module Submit
      class Component < AdminComponent

        attr_reader :form

        def initialize(form)
          @form = form
        end

      end
    end
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/active_dry_form.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
