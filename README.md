# ActiveDryForm

---
Dear ladies and gentlemen, We present to your attention a beautiful dry wrapper for your rail forms,
as well as the ability to implement a form object pattern. Have you been waiting for? Now get...)))!!!

<img src="https://media.tenor.com/KjyW-WcPD68AAAAC/the-office-michael-scott.gif" width="800px" alt="Приветствие">

---
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

Since under the hood `active dry form` are installed [dry-validation](https://dry-rb.org/gems/dry-validation)
, [dry-monads](https://dry-rb.org/gems/dry-monads), action view, active model and action controller.
You do not have to worry about validations, error handling, and
writing complex business logic in models.

### Let's create a base active dry form!

In your form

```ruby
# forms/product_form.rb

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
      key.failure('Не может быть меньше 2 слов') if value.split.size < 2
    end
  end
end
```
In your controller

```ruby
def new
  @form = ProductForm.new
end

def create
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

def update
  product = Product.find(params[:id])

  @form = ProductForm.new(record: product, params: params)
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
  = f.button 'Submit'
```

### If you want to use monads try this...

```ruby
class UserForm < Form
  fields :user do
    params do
      required(:name).filled(:string, min_size?: 2)
      required(:age).filled(:integer)
      required(:email).filled(:string)
      optional(:upload_attachments).maybe(:array)
    end

    # you can add any rules to validate your fields

    rule(:email) do |context:|
      next unless value

      if User.where.not(id: context[:record]&.id).exists?(email: value)
        key.failure(:duplicate)
      end
    end
  end

  action def create
    # Here you can implement any business logic

    product = User.new
    product.attributes = data.except(:upload_attachments)
    product.attachments << data[:upload_attachments]
    product.save!

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
  @form = UserForm.new
end

def create
  @form = UserForm.new(params: params)

  case @form.create
  in Success(product)
    redirect_to product
  else
    render :new
  end
end

def edit
  @form = UserForm.new(record: User.find(params[:id]))
end

def update
  @form = UserForm.new(record: User.find(params[:id]), params: params)

  case @form.update
  in Success(product)
    redirect_to product
  else
    render :edit
  end
end
```

Your view will remain the same

### What is data in dry form?
`data` is a Hash with attributes for which type casting
has been performed
in the same place in params the initial data of the form

```ruby
data => {:price=>1120, :title=>"title"}
data[:price] => 1120
price => '1120'
```

### Form attribute initialization
In your controller
```ruby
def new
  @form = UserForm.new(params: { user: { name: 'Kolya' } })
  @form.attributes = { name: 'Vasya' }
  @form.name = 'Petya'
end
```
or like this

```ruby
def new
  @form = ProductForm.new
  @form.create_default(params[:category_id])
end
```
then in your dry form

```ruby
def create_default(category_id)
  self.category_id = category_id
end
```

### Look at the inputs we have (slim for example)

```slim
- active_dry_form_for @form do |f|
  / input suitable for 'date', 'time', 'date-time', 'integer', 'string', 'boolean'

  = f.input :title, # don't forget to add options if you need
  = f.show_error(:title)
  = f.input_select :category_id, Category.pluck(:name, :id)
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
class Builder

  def input_date_native(field, options = {})
    wrap_input(__method__, field, options) { |opts| date_field(field, opts) }
  end

end
```

### Nested dry form
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

  fields(:user) do
    params do
      optional(:name).maybe(:string)
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
