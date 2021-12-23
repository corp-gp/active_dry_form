# frozen_string_literal: true

require_relative 'app/user'
require_relative 'app/bookmark'
require_relative 'app/nested_has_many_form'

RSpec.describe ActiveDryForm do
  let(:user) { User.create!(name: 'Ivan') }

  context 'when nested form is invalid' do
    it 'returns validation errors' do
      bookmarks_attributes = [
        { url: '', name: 'First' },
        { url: '', name: 'Second' },
      ]
      form = NestedHasManyForm.new(record: user, params_form: { user: { bookmarks: bookmarks_attributes } })
      form.update
      expect(form.errors).to eq({ bookmarks: { 0 => { url: ['должно быть заполнено'] }, 1 => { url: ['должно быть заполнено'] } } })
    end
  end

  context 'when nested form is valid' do
    it 'creates nested model' do
      bookmarks_attributes =
        [
          { url: '/first' },
          { url: '/second' },
        ]
      form = NestedHasManyForm.new(record: user, params_form: { user: { bookmarks: bookmarks_attributes } })
      form.update
      expect(user.bookmarks.pluck(:url)).to eq(%w[/first /second])
    end

    it 'updates nested model' do
      bookmark = user.bookmarks.create!(url: '/first')
      bookmarks_attributes = [
        { url: '/second', id: bookmark.id },
      ]
      form = NestedHasManyForm.new(record: user, params_form: { user: { bookmarks: bookmarks_attributes } })
      expect { form.update }.not_to change(Bookmark, :count)
      expect(bookmark.url).to eq('/second')
    end
  end
end
