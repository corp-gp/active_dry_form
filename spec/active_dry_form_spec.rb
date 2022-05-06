# frozen_string_literal: true

require_relative 'app/user'
require_relative 'app/user_form'
require_relative 'app/custom_validation_form'
require_relative 'app/custom_contract_form'
require_relative 'app/base_validation_form'

RSpec.describe ActiveDryForm do
  include Dry::Monads[:result]

  let(:user) { User.create!(name: 'Ivan') }

  context 'when set form attributes' do
    it 'set signle attribute' do
      form = UserForm.new
      form.name = 'Vasya'
      expect(form.name).to eq 'Vasya'
    end

    it 'set hash' do
      form = UserForm.new
      form.attributes = { name: 'Vasya' }
      expect(form.name).to eq 'Vasya'
    end
  end

  context 'when params is not valid' do
    it 'raises error' do
      expect { UserForm.new(record: user, params: { form: { name: 'Ivan' } }) }.to raise_error("missing param 'user' in `params`")
    end
  end

  context 'when where are validation errors' do
    let(:form) { UserForm.new(record: user, params: { user: { name: '' } }) }

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
      form = CustomValidationForm.new(record: user, params: { user: { name: 'Maria' } })
      form.update
      expect(form.errors).to eq(name: ['Иван не может стать Марией'])
    end
  end

  context 'when custom contact fails' do
    it 'returns validation errors' do
      form = CustomContractForm.new(params: { user: { name: 'Иван' } })
      form.create
      expect(form.errors).to eq(name: ['non-latin symbols detected'])
    end
  end

  context 'when base validation fails' do
    it 'returns validation errors' do
      form = BaseValidationForm.new(record: user, params: { user: { name: 'Maria' } })
      form.update
      expect(form.errors).to eq(nil => ['user is read only'])
    end
  end

  context 'when where are no validation errors' do
    let(:form) { UserForm.new(record: user, params: { user: { name: 'Igor' } }) }

    it 'creates record' do
      form = UserForm.new(params: { user: { name: 'Vasya' } })
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
