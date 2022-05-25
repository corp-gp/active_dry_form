# frozen_string_literal: true

require_relative '../app/user'
require_relative '../app/personal_info'
require_relative '../app/bookmark'
require_relative '../app/user_form'
require_relative '../app/field_variety_form'
require_relative '../app/base_validation_form'
require_relative '../app/nested_has_one_form'
require_relative '../app/nested_has_many_form'

module StubUrlHelpers

  def url_for(*)
    'https://example.com'
  end

  def polymorphic_path(*)
    '/'
  end

end

RSpec.describe ActiveDryForm::FormHelper do
  let(:controller) { ActionView::TestCase::TestController.new }
  let(:context) { controller.view_context.extend(StubUrlHelpers) }

  let(:user) { User.create!(name: 'Ivan') }

  context 'when plain form rendered' do
    it 'shows fields' do
      form = UserForm.new(record: user)
      html = context.active_dry_form_for(form) { |f| f.input :name }

      expect(html).to include('required')
      expect(html).to include('value="Ivan"')
      expect(html).to include('name="user[name]"')
    end

    it 'shows various input types' do
      form = FieldVarietyForm.new
      html =
        context.active_dry_form_for(form) do |f|
          concat f.input_hidden :id
          concat f.input :age
          concat f.input :is_retail
          concat f.input :password
          concat f.input :email
          concat f.input :phone
          concat f.input :url
          concat f.input_text :about
          concat f.input :birthday
          concat f.input :call_on
        end

      expect(html).to include('type="hidden"')
      expect(html).to include('type="number"')
      expect(html).to include('type="checkbox"')
      expect(html).to include('type="password"')
      expect(html).to include('type="email"')
      expect(html).to include('type="tel"')
      expect(html).to include('type="url"')
      expect(html).to include('textarea')
      expect(html).to include('flatpickr')
      expect(html).to include('data-flatpickr-enable-time')
    end

    it 'shows validation errors' do
      form = UserForm.new(record: user, params: { user: { name: '' } })
      form.update

      html = context.active_dry_form_for(form) { |f| f.input :name }

      expect(html).to include('должно быть заполнено')
    end

    it 'shows base validation errors' do
      form = BaseValidationForm.new(record: user, params: { user: { name: 'Maria' } })
      form.update

      html = context.active_dry_form_for(form) { |f| f.input :name }

      expect(html).to include('user is read only')
    end

    it 'shows readonly field' do
      form = UserForm.new(record: user)

      html = context.active_dry_form_for(form) { |f| f.input :name, readonly: true }

      expect(html).to include('readonly')
      expect(html).to include('value="Ivan"')
      expect(html).to include('name="user[name]"')
    end

    it 'does not show `required` attribute and class name of `input` if it is explicity set to `false`' do
      form = UserForm.new(record: user)
      html =
        context.active_dry_form_for(form) do |f|
          f.input :name, required: false
        end

      expect(html).not_to include('required')
    end

    it 'shows select with `required` attribute' do
      form = UserForm.new(record: user)
      html =
        context.active_dry_form_for(form) do |f|
          f.input_select :name, %w[Ivan Boris], { include_blank: 'A boy has no name' }
        end

      expect(html).to include('<select')
      expect(html).to include('name="user[name]"')
      expect(html).to include('required')
      expect(html).to include('<option value="">A boy has no name</option>')
      expect(html).to include('<option selected="selected" value="Ivan">Ivan</option>')
      expect(html).to include('<option value="Boris">Boris</option>')
    end

    it 'does not show `required` attribute and class name of `select` if it is explicity set to `false`' do
      form = UserForm.new(record: user)
      html =
        context.active_dry_form_for(form) do |f|
          f.input_select :name, %w[Ivan], {}, { required: false }
        end

      expect(html).to include('<select')
      expect(html).not_to include('required')
    end
  end

  context 'when single nested form rendered' do
    it 'shows nested fields' do
      form = NestedHasOneForm.new(record: user)
      html =
        context.active_dry_form_for(form) do |f|
          f.fields_for(:personal_info) { |sf| sf.input(:age) }
        end

      expect(html).to include('required')
      expect(html).to include('type="number"')
      expect(html).to include('name="user[personal_info][age]"')
    end

    it 'shows nested errors' do
      form = NestedHasOneForm.new(record: user, params: { user: { personal_info: { age: '' } } })
      form.update
      html =
        context.active_dry_form_for(form) do |f|
          f.fields_for(:personal_info) { |sf| sf.input(:age) }
        end

      expect(html).to include('должно быть заполнено')
    end
  end

  context 'when multiple nested form rendered' do
    before(:each) { user.bookmarks.build }

    it 'shows nested fields' do
      form = NestedHasManyForm.new(record: user)
      html =
        context.active_dry_form_for(form) do |f|
          f.fields_for(:bookmarks) do |sf|
            sf.input(:url)
          end
        end

      expect(html).to include('required')
      expect(html).to include('type="url"')
      expect(html).to include('name="user[bookmarks][][url]"')
    end

    it 'shows nested errors' do
      bookmarks_attributes = [
        { url: '' },
      ]
      form = NestedHasManyForm.new(record: user, params: { user: { bookmarks: bookmarks_attributes } })
      form.update
      html =
        context.active_dry_form_for(form) do |f|
          f.fields_for(:bookmarks) do |sf|
            sf.input(:url)
          end
        end

      expect(html).to include('должно быть заполнено')
    end
  end
end
