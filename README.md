# ActiveDryForm
## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_dry_form'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install active_dry_form
---

## Base Usage

### Under the hood ActiveDryForm [dry-validation](https://dry-rb.org/gems/dry-validation), [dry-monads](https://dry-rb.org/gems/dry-monads)

```ruby
form = ProductForm.new(record: Product.find(1), params: { product: { title: 'n', price: 120 } })

form.validate # => checks field validity
form.validator # => #<Dry::Validation::Result{
                      # :title=>"n",
                      # :price=>120
                      # errors={:name=>["minimum length 2"]}
                      # context={:form=>{:name=>"n", :price=>120},
                      # :record=>#<Product id: 1, title: 'name', price: 100, description: 'product'}>
form.valid? # => false
form.persisted? # => true
form.errors # => {:name=>["minimum length 2"]}
form.base_errors = []
form.errors_full_messages # => ['Cannot be less than 2 words']
form.record # => #<Product:0x00007f05c27106c8 id: 1, title: 'name', price: 100, description: 'product'>
form.data # => {:title=>"n", :price=>120}
form.data[:price] # => 120
form.price # => '120'
form.name # => 'n'
form.update # Failure(:invalid_form)
```

Methods `form.update` and `form.create` return [Result monad](https://dry-rb.org/gems/dry-monads/1.3/result/)

```ruby
# app/forms/product_form.rb

class ProductForm < Form
  fields :product do
    params do
      required(:title).filled(:string, min_size?: 2)
      required(:price).filled(:integer)
      optional(:description).maybe(:string)
      optional(:upload_attachments).maybe(:array)
    end

    # you can add any rules to validate your fields

    rule(:description) do
      key.failure('Cannot be less than 2 words') if value.split.size < 2
    end
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
class ProductsController < ApplicationController
  include Dry::Monads[:result]

  def new
    @form = ProductForm.new
  end

  def create # without monads
    @form = ProductForm.new(params: params)
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

  def update # with monads
    product = Product.find(params[:id])

    @form = ProductForm.new(record: product, params: params)

    case @form.update
    in Success(product)
      redirect_to product
    else
      render :edit
    end
  end
end
```

in your view (slim for example)

```slim
/ app/views/products/new.slim

- active_dry_form_for @form do |f|
  = f.input :title
  = f.input :price
  = f.input_select :status, Product::STATUSES.values
  = f.input_file :upload_attachments, multiple: true, label: false
  = f.button 'Submit'
```

### Form attribute initialization

In your controller

```ruby
def new
  @form = ProductForm.new(params: { product: { title: 'name', price: 120 } })
  @form.attributes = { title: 'new name', price: 100}
  @form.description = 'product description'
end
```

or like this

```ruby
def new
  @form = ProductForm.new
  @form.create_default(params[:title])
end
```

then in your dry form

```ruby
def create_default(title)
  self.title = title
end
```

### Look at the inputs we have (slim for example)

`input` method automatically determines tag type by data type
(date, time, integer, number, string, boolean, password, email, telephone, url)

```slim
- active_dry_form_for @form, html: { 'data-controller': 'product'} do |f|
  = f.input :title, 'data-product-target': 'title', readonly: true,
  = f.show_error(:title)
  = f.input_select :category_id, Category.pluck(:name, :id),
    { include_blank: true },
    { label: false, multiple: true, style: 'max-width:unset;'}
  = f.input_check_box :is_discount
  = f.input_checkbox_inline :is_sale
  = f.input_text :shipper_name
  = f.input_text_area :description
  = f.input_hidden :admin_id
  = f.input_file :upload_attachments, multiple: true, label: false
  = f.input_date :date
  = f.input_datetime :date_time
  = f.input_integer :category_id
  = f.input_number :number
  = f.input_password :password
  = f.input_email :email
  = f.input_url :url
  = f.input_telephone :telephone

  = f.button 'Submit'
```

### You can create your own input

```ruby
# lib/acitve_dry_form/builder.rb

module ActiveDryForm
  class Builder

    def input_date_native(field, options = {})
      wrap_input(__method__, field, options) { |opts| date_field(field, opts) }
    end

  end
end
```

### The form can be nested

```ruby
class NestedDryForm < Form

  class BookmarkForm < Form

    fields(:bookmark) do
      params do
        required(:url).filled(:string)
        optional(:id).maybe(:integer)
        optional(:name).maybe(:string)
      end
    end

  end

  fields :product do
    params do
      required(:title).filled(:string, min_size?: 2)
      required(:price).filled(:integer)
      optional(:description).maybe(:string)
      optional(:upload_attachments).maybe(:array)
      optional(:bookmarks).array(Dry.Types::Instance(BookmarkForm))
    end
  end

  action def update
    bookmarks_data = data.delete(:bookmarks)

    record.attributes = data
    record.bookmarks_attributes = bookmarks_data if bookmarks_data
    record.save!

    Success(record)
  end

end
```

As you noticed in the above example, we use the construction `Dry.Types::Instance(BookmarkForm)`,
what it is `dry types` you can find out [here](https://dry-rb.org/gems/dry-types)

---

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

---

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/active_dry_form.

---

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
