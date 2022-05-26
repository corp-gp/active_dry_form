# frozen_string_literal: true

require_relative '../app/user'
require_relative '../app/personal_info'
require_relative '../app/bookmark'
require_relative '../app/user_form'
require_relative '../app/field_variety_form'
require_relative '../app/base_validation_form'
require_relative '../app/nested_has_one_form'
require_relative '../app/nested_has_many_form'
I18n.load_path = ["#{__dir__}/../app/en.yml"]

module StubUrlHelpers

  def url_for(*)
    'https://example.com'
  end

  def polymorphic_path(*)
    '/'
  end

end

def clean_html(html)
  html.delete("\n").gsub(/>\s+</, '><')
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

    it 'renders select' do
      form = UserForm.new(record: user)
      html =
        context.active_dry_form_for(form) do |f|
          f.input_select :name, %w[Ivan Boris], { include_blank: 'A boy has no name' }
        end

      expected_html = <<~HTML
        <div class="input input_select string name required">
          <label for="user_name">User Name</label>
          <select required="required" data-controller="select-tag" name="user[name]" id="user_name">
            <option value="">A boy has no name</option>
            <option selected="selected" value="Ivan">Ivan</option>
            <option value="Boris">Boris</option>
          </select>
        </div>
      HTML

      expect(clean_html(html)).to include(clean_html(expected_html))
    end

    context 'when required explicitly disabled' do
      it 'renders select tag without required attribute and wrapper class' do
        form = UserForm.new(record: user)
        html =
          context.active_dry_form_for(form) do |f|
            f.input_select :name, %w[Ivan], {}, { required: false }
          end

        expected_html = <<~HTML
          <div class="input input_select string name">
            <label for="user_name">User Name</label>
            <select data-controller="select-tag" name="user[name]" id="user_name">
              <option selected="selected" value="Ivan">Ivan</option>
            </select>
          </div>
        HTML

        expect(clean_html(html)).to include(clean_html(expected_html))
      end

      it 'renders input tag without required attribute and wrapper class' do
        form = UserForm.new(record: user)
        html = context.active_dry_form_for(form) { |f| f.input :name, required: false }

        expected_html = <<~HTML
          <div class="input input string name">
            <label for="user_name">User Name</label>
            <input type="text" value="Ivan" name="user[name]" id="user_name" />
          </div>
        HTML

        expect(clean_html(html)).to include(clean_html(expected_html))
      end
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
