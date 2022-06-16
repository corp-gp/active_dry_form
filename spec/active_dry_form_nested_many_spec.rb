# frozen_string_literal: true

require_relative 'app/user'
require_relative 'app/bookmark'
require_relative 'app/nested_has_many_form'

RSpec.describe ActiveDryForm do
  let(:user) { User.create!(name: 'Ivan') }

  context 'when nested record is an association' do
    context 'when form is invalid' do
      it 'returns validation errors' do
        bookmarks_attributes = [
          { url: '', name: 'First' },
          { url: '', name: 'Second' },
        ]
        form = NestedHasManyForm.new(record: user, params: { user: { bookmarks: bookmarks_attributes } })
        form.update
        expect(form.errors).to eq({ bookmarks: { 0 => { url: ['должно быть заполнено'] }, 1 => { url: ['должно быть заполнено'] } } })
      end
    end

    context 'when form is valid' do
      it 'creates nested model' do
        bookmarks_attributes =
          [
            { url: '/first' },
            { url: '/second' },
          ]
        form = NestedHasManyForm.new(record: user, params: { user: { bookmarks: bookmarks_attributes } })
        form.update
        expect(user.bookmarks.pluck(:url)).to eq(%w[/first /second])
      end

      it 'updates nested model' do
        bookmark = user.bookmarks.create!(url: '/first')
        bookmarks_attributes = [
          { url: '/second', id: bookmark.id },
        ]
        form = NestedHasManyForm.new(record: user, params: { user: { bookmarks: bookmarks_attributes } })
        expect { form.update }.not_to change(Bookmark, :count)
        expect(bookmark.url).to eq('/second')
      end
    end
  end

  context 'when nested record is a hash' do
    context 'when form is invalid' do
      it 'returns validation errors' do
        favorites_attributes = [
          { kind: '', name: 'First' },
          { kind: '', name: 'Second' },
        ]
        form = NestedHasManyForm.new(record: user, params: { user: { favorites: favorites_attributes } })
        form.update
        expect(form.errors).to eq({ favorites: { 0 => { kind: ['должно быть заполнено'] }, 1 => { kind: ['должно быть заполнено'] } } })
      end
    end

    context 'when form is valid' do
      it 'creates nested model' do
        favorites_attributes =
          [
            { kind: 'book', name: '1984' },
            { kind: 'movie', name: 'Planet of Monkeys' },
          ]
        form = NestedHasManyForm.new(record: user, params: { user: { favorites: favorites_attributes } })
        form.update
        expect(user.favorites).to eq [{ 'kind' => 'book', 'name' => '1984' }, { 'kind' => 'movie', 'name' => 'Planet of Monkeys' }]
      end

      it 'updates nested model' do
        user.update!(favorites: [{ kind: 'book', name: '1984' }])
        favorites_attributes = [
          { kind: 'movie', name: 'Planet of Monkeys' },
        ]
        form = NestedHasManyForm.new(record: user, params: { user: { favorites: favorites_attributes } })
        form.update
        expect(user.favorites).to eq [{ 'kind' => 'movie', 'name' => 'Planet of Monkeys' }]
      end
    end
  end
end
