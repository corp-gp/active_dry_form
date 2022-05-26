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

RSpec.describe ActiveDryForm::FormHelper do
  let(:controller) { ActionView::TestCase::TestController.new }
  let(:context) { controller.view_context.extend(StubUrlHelpers) }

  let(:user) { User.create!(name: 'Ivan') }

  context 'when plain form rendered' do
    it 'renders input with additional attributes' do
      form = UserForm.new(record: user)
      html = context.active_dry_form_for(form) { |f| f.input :name, readonly: true }

      expected_html = <<-HTML
        <div class="input input string name required">
          <label for="user_name">User Name</label>
          <input readonly="readonly" required="required" type="text" value="Ivan" name="user[name]" id="user_name" />
        </div>
      HTML

      expect(html).to include_html(expected_html)
    end

    it 'renders input with validation errors' do
      form = UserForm.new(record: user, params: { user: { name: '' } })
      form.update

      html = context.active_dry_form_for(form) { |f| f.input :name }

      expected_html = <<-HTML
        <div class="input input string name required error">
          <label for="user_name">User Name</label>
          <input required="required" type="text" name="user[name]" id="user_name" />
          <div class="form-error is-visible">должно быть заполнено</div>
        </div>
      HTML

      expect(html).to include_html(expected_html)
    end

    it 'renders base validation errors' do
      form = BaseValidationForm.new(record: user, params: { user: { name: 'Maria' } })
      form.update

      html = context.active_dry_form_for(form) { |f| concat f.input :name }

      expected_html = <<-HTML
        <div class="callout alert form-base-error">
          <ul><li>user is read only</li></ul>
        </div>
        <div class="input input string name">
          <label for="user_name">User Name</label>
          <input type="text" value="Maria" name="user[name]" id="user_name" />
        </div>
      HTML

      expect(html).to include_html(expected_html)
    end

    describe 'various input types' do
      let(:form) { FieldVarietyForm.new }

      it 'renders text input' do
        html = context.active_dry_form_for(form) { |f| f.input :name }
        expected_html = <<-HTML
          <div class="input input string name">
            <label for="user_name">User Name</label>
            <input type="text" name="user[name]" id="user_name" />
          </div>
        HTML

        expect(html).to include_html(expected_html)
      end

      it 'renders hidden input' do
        html = context.active_dry_form_for(form) { |f| f.input_hidden :id }
        expected_html = <<-HTML
        <input autocomplete="off" type="hidden" name="user[id]" id="user_id" />
        HTML

        expect(html).to include_html(expected_html)
      end

      it 'renders integer input' do
        html = context.active_dry_form_for(form) { |f| f.input :age }
        expected_html = <<-HTML
        <div class="input input integer age">
          <label for="user_age">User Age</label>
          <input type="number" name="user[age]" id="user_age" />
        </div>
        HTML

        expect(html).to include_html(expected_html)
      end

      it 'renders boolean checkbox' do
        html = context.active_dry_form_for(form) { |f| f.input :is_retail }
        expected_html = <<-HTML
        <div class="input input boolean is_retail">
          <label for="user_is_retail">User Is Retail</label>
          <input name="user[is_retail]" type="hidden" value="0" autocomplete="off" />
          <input type="checkbox" value="1" name="user[is_retail]" id="user_is_retail" />
        </div>
        HTML

        expect(html).to include_html(expected_html)
      end

      it 'renders password input' do
        html = context.active_dry_form_for(form) { |f| f.input :password }
        expected_html = <<-HTML
        <div class="input input string password">
          <label for="user_password">User Password</label>
          <input type="password" name="user[password]" id="user_password" />
        </div>
        HTML

        expect(html).to include_html(expected_html)
      end

      it 'renders email input' do
        html = context.active_dry_form_for(form) { |f| f.input :email }
        expected_html = <<-HTML
        <div class="input input string email">
          <label for="user_email">User Email</label>
          <input type="email" name="user[email]" id="user_email" />
        </div>
        HTML

        expect(html).to include_html(expected_html)
      end

      it 'renders tel input' do
        html = context.active_dry_form_for(form) { |f| f.input :phone }
        expected_html = <<-HTML
        <div class="input input string phone">
          <label for="user_phone">User Phone</label>
          <input type="tel" name="user[phone]" id="user_phone" />
        </div>
        HTML

        expect(html).to include_html(expected_html)
      end

      it 'renders url input' do
        html = context.active_dry_form_for(form) { |f| f.input :url }
        expected_html = <<-HTML
        <div class="input input string url">
          <label for="user_url">User Url</label>
          <input type="url" name="user[url]" id="user_url" />
        </div>
        HTML

        expect(html).to include_html(expected_html)
      end

      it 'renders textarea' do
        html = context.active_dry_form_for(form) { |f| f.input_text :about }
        expected_html = <<-HTML
        <div class="input input_text string about">
          <label for="user_about">User About</label>
          <textarea name="user[about]" id="user_about"></textarea>
        </div>
        HTML

        expect(html).to include_html(expected_html)
      end

      it 'renders date input' do
        html = context.active_dry_form_for(form) { |f| f.input :birthday }
        expected_html = <<-HTML
        <div class="input input date birthday">
          <label for="user_birthday">User Birthday</label>
            <input data-controller="flatpickr" type="text" name="user[birthday]" id="user_birthday" />
        </div>
        HTML

        expect(html).to include_html(expected_html)
      end

      it 'renders date_time input' do
        html = context.active_dry_form_for(form) { |f| f.input :call_on }
        expected_html = <<-HTML
        <div class="input input date-time call_on">
          <label for="user_call_on">User Call On</label>
            <input data-controller="flatpickr" data-flatpickr-enable-time="true" type="text" name="user[call_on]" id="user_call_on" />
        </div>
        HTML

        expect(html).to include_html(expected_html)
      end

      it 'renders select' do
        html =
          context.active_dry_form_for(form) do |f|
            f.input_select :name, %w[Ivan Boris], { include_blank: 'A boy has no name' }
          end

        expected_html = <<-HTML
          <div class="input input_select string name">
            <label for="user_name">User Name</label>
            <select data-controller="select-tag" name="user[name]" id="user_name">
              <option value="">A boy has no name</option>
              <option value="Ivan">Ivan</option>
              <option value="Boris">Boris</option>
            </select>
          </div>
        HTML

        expect(html).to include_html(expected_html)
      end
    end

    context 'when required explicitly enabled for optional field' do
      it 'renders select with required attribute and wrapper class' do
        form = UserForm.new(record: user)
        html =
          context.active_dry_form_for(form) do |f|
            f.input_select :second_name, %w[Ivan], {}, { required: true }
          end

        expected_html = <<-HTML
          <div class="input input_select string second_name required">
            <label for="user_second_name">User Second Name</label>
            <select required="required" data-controller="select-tag" name="user[second_name]" id="user_second_name"><option value="" label=" "></option>
              <option value="Ivan">Ivan</option>
            </select>
          </div>
        HTML

        expect(html).to include_html(expected_html)
      end

      it 'renders text input with required attribute and wrapper class' do
        form = UserForm.new(record: user)
        html = context.active_dry_form_for(form) { |f| f.input :second_name, required: true }

        expected_html = <<-HTML
          <div class="input input string second_name required">
            <label for="user_second_name">User Second Name</label>

            <input required="required" type="text" name="user[second_name]" id="user_second_name" />
          </div>
        HTML

        expect(html).to include_html(expected_html)
      end
    end
  end

  context 'when single nested form rendered' do
    it 'renders input' do
      form = NestedHasOneForm.new(record: user)
      html =
        context.active_dry_form_for(form) do |f|
          f.fields_for(:personal_info) { |sf| sf.input(:age) }
        end

      expected_html = <<-HTML
        <div class="input input integer age required">
          <label for="user_personal_info_age">Perconal Info Age</label>
          <input required="required" type="number" name="user[personal_info][age]" id="user_personal_info_age" />
        </div>
      HTML

      expect(html).to include_html(expected_html)
    end

    it 'renders input with errors' do
      form = NestedHasOneForm.new(record: user, params: { user: { personal_info: { age: '' } } })
      form.update
      html =
        context.active_dry_form_for(form) do |f|
          f.fields_for(:personal_info) { |sf| sf.input(:age) }
        end

      expected_html = <<-HTML
        <div class="input input integer age required error">
          <label for="user_personal_info_age">Perconal Info Age</label>
          <input required="required" type="number" name="user[personal_info][age]" id="user_personal_info_age" />
          <div class="form-error is-visible">должно быть заполнено</div>
        </div>
      HTML

      expect(html).to include_html(expected_html)
    end
  end

  context 'when multiple nested form rendered' do
    before(:each) { user.bookmarks.build }

    it 'renders input' do
      form = NestedHasManyForm.new(record: user)
      html =
        context.active_dry_form_for(form) do |f|
          f.fields_for(:bookmarks) do |sf|
            sf.input(:url)
          end
        end

      expected_html = <<-HTML
        <div class="input input string url required">
          <label for="user_bookmarks__url">Bookmarks URL</label>
          <input required="required" type="url" name="user[bookmarks][][url]" id="user_bookmarks__url" />
        </div>
      HTML

      expect(html).to include_html(expected_html)
    end

    it 'renders input with errors' do
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

      expected_html = <<-HTML
        <div class="input input string url required error">
          <label for="user_bookmarks__url">Bookmarks URL</label>
          <input required="required" type="url" name="user[bookmarks][][url]" id="user_bookmarks__url" />
          <div class="form-error is-visible">должно быть заполнено</div>
        </div>
      HTML

      expect(html).to include_html(expected_html)
    end
  end
end
