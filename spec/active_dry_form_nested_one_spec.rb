# frozen_string_literal: true

require_relative 'app/user'
require_relative 'app/personal_info'
require_relative 'app/nested_has_one_form'

RSpec.describe ActiveDryForm do
  let(:user) { User.create!(name: 'Ivan') }

  context 'when nested record is an association' do
    context 'when form is invalid' do
      it 'returns validation errors' do
        form = NestedHasOneForm.new(record: user, params: { user: { personal_info: { age: '' } } })
        form.update
        expect(form.valid?).to be(false)
        expect(form.errors).to eq({ personal_info: { age: ['должно быть заполнено'] } })
      end

      it 'returns typecasted value after validation' do
        form = NestedHasOneForm.new(record: user, params: { user: { personal_info: { date_of_birth: Date.current.to_s } } })
        form.update
        expect(form.personal_info.date_of_birth).to eq Date.current
      end
    end

    context 'when form is valid' do
      let(:form) { NestedHasOneForm.new(record: user, params: { user: { personal_info: { age: '20' } } }) }

      it 'creates nested model' do
        form.update
        expect(form.valid?).to be(true)
        expect(user.personal_info.age).to eq 20
      end

      it 'updates nested model' do
        user.create_personal_info!(age: 18)
        expect { form.update }.to change { user.personal_info.age }.to(20)
      end
    end
  end

  context 'when nested record is a hash' do
    context 'when form is invalid' do
      it 'returns validation errors' do
        form = NestedHasOneForm.new(record: user, params: { user: { dimensions: { height: '' } } })
        form.update
        expect(form.valid?).to be(false)
        expect(form.errors).to eq({ dimensions: { height: ['должно быть заполнено'] } })
      end
    end

    context 'when form is valid' do
      let(:form) { NestedHasOneForm.new(record: user, params: { user: { dimensions: { height: 180 } } }) }

      it 'creates nested model' do
        form.update
        expect(form.valid?).to be(true)
        expect(user.dimensions).to eq('height' => 180)
      end

      it 'updates nested model' do
        user.update!(dimensions: { height: 170 })
        expect { form.update }.to change(user, :dimensions).to('height' => 180)
      end
    end
  end
end
