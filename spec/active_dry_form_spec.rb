# frozen_string_literal: true

require_relative 'support/user_form'
require_relative 'support/user'

RSpec.describe ActiveDryForm do
  include Dry::Monads[:result]

  context 'when where are validation errors' do
    let(:user) { User.new(name: 'Ivan') }
    let(:form) { UserForm.new(record: user, params_form: { user: { name: '' } }) }

    it 'doesnt update record' do
      expect { form.update }.not_to change(user, :name)
    end

    it 'returns Failure' do
      expect(form.update).to eq Failure(:validate_invalid)
    end

    it 'returns validation errors' do
      form.update
      expect(form.errors).to eq(name: ['должно быть заполнено'])
    end
  end

  context 'when custom validation fails' do
    it 'returns validation errors' do
      user = User.new(name: 'Ivan')
      form = UserForm.new(record: user, params_form: { user: { name: 'Maria' } })
      form.update
      expect(form.errors).to eq(name: ['Иван не может стать Марией'])
    end
  end

  context 'when where are no validation errors' do
    let(:user) { User.new(name: 'Ivan') }
    let(:form) { UserForm.new(record: user, params_form: { user: { name: 'Igor' } }) }

    it 'update record' do
      expect { form.update }.to change(user, :name).to('Igor')
    end

    it 'returns Success with record itself' do
      expect(form.update).to eq Success(user)
    end
  end
end
