# ActiveDryForm


Dear ladies and gentlemen, We present to your attention a beautiful dry wrapper for your rail forms,
as well as the ability to implement a form object pattern. Have you been waiting for? Now get...)))!!!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_dry_form'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install active_dry_form

## Base Usage

Let's create a dry mold first. Let's imagine that we have a Product model with the
fields price (integer), upload_attachments (array) , title (string), status (string).
Since under the hood active_dry_form are installed
dry-validation https://dry-rb.org/gems/dry-validation/1.8/
and dry-monads https://dry-rb.org/gems/dry-monads/1.3/.
You do not have to worry about validations, error handling,
writing and complex business logic in models

```ruby
class ProductForm < Form
  fields :product do
    params do
      required(:title).filled(:string, min_size?: 2)
      required(:price).filled(:integer)
      optional(:upload_attachments).maybe(:array)
    end

    # you can add any rules to validate your fields
  end

  action def create
    product = Product.create!(data.merge(administrator_id: current_admin.id))
    Success(product)
  end

  action def update
    record.update!(data)
    Success(record)
  end
end
```
In your controller

```ruby
include Dry::Monads[:result]

def new
  @form = ProductForm.new
end

def create
  @form = ProductForm.new(params: request.params)

  case @form.create
  in Success(product)
    redirect_to product
  else
    render :new
  end
end

def edit
  @form = ProductForm.new(record: Product.find(params[:id]))
end

def update
  @form = ProductForm.new(record: Product.find(params[:id]), params: request.params)

  case @form.update
  in Success(product)
    redirect_to product
  else
    render :edit
  end
end
```

in your view (slim for example)

```slim
- active_dry_form_for @form do |f|
  = f.input :title
  = f.input :price
  = f.input_select :status, Product::STATUSES
  = f.input_file :upload_attachments, multiple: true, label: false
end
```
like it, shall we continue?

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/active_dry_form.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

