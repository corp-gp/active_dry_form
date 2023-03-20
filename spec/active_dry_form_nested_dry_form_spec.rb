# frozen_string_literal: true

require_relative 'app/user'
require_relative 'app/bookmark'
require_relative 'app/personal_info'
require_relative 'app/nested_dry_form'

RSpec.describe ActiveDryForm do
  let(:user) { User.create!(name: 'Ivan') }

  context 'when form is valid' do
    it 'creates nested model' do
      bookmarks_attributes = [{ url: 'https://omniplatform.ru' }]
      personal_info_attributes = { age: 25 }
      form = NestedDryForm.new(record: user)
      form.attributes = { bookmarks: bookmarks_attributes, personal_info: personal_info_attributes }
      form.update
      expect(user.bookmarks[0].url).to eq('https://omniplatform.ru')
      expect(user.personal_info.age).to eq 25
    end

    it 'updates nested model' do
      bookmark = user.bookmarks.create!(url: 'https://google.com')
      bookmarks_attributes = [{ url: 'https://omniplatform.ru', id: bookmark.id }]
      user.build_personal_info(age: 18)
      user.personal_info.save!
      personal_info_attributes = { age: 25, id: user.personal_info.id }
      form = NestedDryForm.new(record: user)
      form.attributes = { bookmarks: bookmarks_attributes, personal_info: personal_info_attributes }
      expect { form.update }.not_to change { [Bookmark.count, PersonalInfo.count] }
      expect(user.bookmarks[0].url).to eq('https://omniplatform.ru')
      expect(user.personal_info.age).to eq 25
    end
  end

  context 'when form is invalid' do
    it 'returns validation errors' do
      bookmarks_attributes = [{ url: '' }]
      personal_info_attributes = { age: 17 }
      form = NestedDryForm.new(record: user)
      form.attributes = { bookmarks: bookmarks_attributes, personal_info: personal_info_attributes }
      form.update
      expect(form.valid?).to be(false)
      expect(form.personal_info.errors).to eq(age: ['должно быть больше или равным 18'])
      expect(form.bookmarks[0].errors).to eq(url: ['должно быть заполнено'])
    end

    it 'returns typecasted value after validation' do
      form = NestedDryForm.new(record: user, params: { user: { personal_info: { date_of_birth: Date.current.to_s } } })
      form.update
      expect(form.personal_info.date_of_birth).to eq Date.current
    end
  end
end
