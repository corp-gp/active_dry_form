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


Since under the hood active_dry_form are installed
dry-validation
and dry-monads ,
action view, active model and action controller.
You do not have to worry about validations, error handling, and
writing complex business logic in models.

### Let's create a base active dry form without monads!

In your form

```ruby
# forms/product_form.rb

class ProductForm < Form
  fields :product do
    params do
      required(:title).filled(:string, min_size?: 2)
      required(:price).filled(:integer)
      optional(:upload_attachments).maybe(:array)
    end

    # you can add any rules to validate your fields
  end
end
```
In your controller

```ruby
def new
  @form = ProductForm.new
end

def create
  @form = ProductForm.new(params: request.params)
  @form.validate

  if @form.valid?
    Product.create!(@form)

    redirect_to products_path
  else
    render :new
  end
end

def edit
  @form = ProductForm.new(record: Product.find(params[:id]))
end

def update
  product = Product.find(params[:id])

  @form = ProductForm.new(record: product, params: request.params)
  @form.validate

  if @form.valid?
    product.update!(@form)

    redirect_to products_path
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
  = f.input_select :status, Product::STATUSES.values
  = f.input_file :upload_attachments, multiple: true, label: false
  = f.button 'Сохранить'
```

### If you want to use monads try this...

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
    # Here you can implement any business logic

    product = Product.create!(data)
    Success(product)
  end

  action def update
    # Here you can implement any business logic

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

Your view will remain the same

## Look at all the inputs we have.

```slim
- active_dry_form_for @form do |f|
  / input suitable for 'date', 'time', 'date-time', 'integer',
  /'string', 'boolean'
  = f.input :title
  = f.input :price
  = f.input_select :category_id, Category.pluck(:name, :id)
  = f.input_checkbox_inline :is_sale
  = f.input_text :shipper_name
  = f.input_text_area :description
  = f.input_hidden :admin_id
  = f.input_file :upload_attachments, multiple: true, label: false
  = f.button 'Сохранить'

```

## You can set default values in inputs
  In your controller

  ```ruby
  def new
    @form = ProductForm.new
    @form.create_default(params[:category_id])
  end
  ```
In your form

```ruby
  def create_default(category_id)
    form.category_id = category_id
  end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/active_dry_form.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

