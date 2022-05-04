# frozen_string_literal: true

require_relative 'app/user'
require_relative 'app/user_form'
require_relative 'app/custom_validation_form'
require_relative 'app/custom_contract_form'
require_relative 'app/base_validation_form'
require_relative 'app/default_create_form'

RSpec.describe ActiveDryForm do
  include Dry::Monads[:result]

  let(:user) { User.create!(name: 'Ivan') }

  context 'when form has defaults' do
    it 'initializes form with defaults' do
      form = DefaultCreateForm.new
      form.create_default
      expect(form.name).to eq 'Vasya'
    end
  end

  context 'when params_form is not valid' do
    it 'raises error' do
      expect { UserForm.new(record: user, params_form: { form: { name: 'Ivan' } }) }.to raise_error("missing param 'user' in `params_form`")
    end
  end

  context 'when where are validation errors' do
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
      form = CustomValidationForm.new(record: user, params_form: { user: { name: 'Maria' } })
      form.update
      expect(form.errors).to eq(name: ['Иван не может стать Марией'])
    end
  end

  context 'when custom contact fails' do
    it 'returns validation errors' do
      form = CustomContractForm.new(params_form: { user: { name: 'Иван' } })
      form.create
      expect(form.errors).to eq(name: ['non-latin symbols detected'])
    end
  end

  context 'when base validation fails' do
    it 'returns validation errors' do
      form = BaseValidationForm.new(record: user, params_form: { user: { name: 'Maria' } })
      form.update
      expect(form.errors).to eq(nil => ['user is read only'])
    end
  end

  context 'when where are no validation errors' do
    let(:form) { UserForm.new(record: user, params_form: { user: { name: 'Igor' } }) }

    it 'creates record' do
      form = UserForm.new(params_form: { user: { name: 'Vasya' } })
      expect { form.create }.to change(User, :count).by(1)
    end

    it 'updates record' do
      expect { form.update }.to change(user, :name).to('Igor')
    end

    it 'returns Success with record itself' do
      expect(form.update).to eq Success(user)
    end
  end
end
