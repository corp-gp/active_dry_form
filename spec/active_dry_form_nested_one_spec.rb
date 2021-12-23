# frozen_string_literal: true

require_relative 'app/user'
require_relative 'app/personal_info'
require_relative 'app/nested_has_one_form'

RSpec.describe ActiveDryForm do
  let(:user) { User.create!(name: 'Ivan') }

  context 'when nested form is invalid' do
    it 'returns validation errors' do
      form = NestedHasOneForm.new(record: user, params_form: { user: { personal_info: { age: '' } } })
      form.update
      expect(form.errors).to eq({ personal_info: { age: ['должно быть заполнено'] } })
    end
  end

  context 'when nested form is valid' do
    let(:form) { NestedHasOneForm.new(record: user, params_form: { user: { personal_info: { age: '20' } } }) }

    it 'creates nested model' do
      form.update
      expect(user.personal_info.age).to eq 20
    end

    it 'updates nested model' do
      user.create_personal_info!(age: 18)
      expect { form.update }.to change { user.personal_info.age }.to(20)
    end
  end
end
