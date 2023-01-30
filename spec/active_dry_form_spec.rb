# frozen_string_literal: true

require_relative 'app/user'
require_relative 'app/user_form'
require_relative 'app/custom_validation_form'
require_relative 'app/nested_has_one_form'
require_relative 'app/nested_has_many_form'
require_relative 'app/custom_contract_form'
require_relative 'app/base_validation_form'
require_relative 'app/filter_blank_form'
require_relative 'app/loose_json_schema_form'

RSpec.describe ActiveDryForm do
  include Dry::Monads[:result]

  let(:user) { User.create!(name: 'Ivan') }

  context 'when set form attributes' do
    it 'set single attribute' do
      form = UserForm.new
      form.name = 'Vasya'
      expect(form.name).to eq 'Vasya'
    end

    it 'set hash' do
      form = UserForm.new
      form.attributes = { name: 'Vasya' }
      expect(form.name).to eq 'Vasya'
    end

    it 'set hash with unknown key' do
      described_class.config.strict_param_keys = false

      form = UserForm.new

      expect {
        form.attributes = { first_name: 'Vasya' }
      }.not_to raise_error

      described_class.reset_config
    end

    it 'read attribute form record' do
      form = UserForm.new(record: user)
      expect(form.name).to eq 'Ivan'
    end

    it 'read attribute form params' do
      user.update!(second_name: 'Sidorov')

      form = UserForm.new(record: user, params: { user: { name: 'Ivan', second_name: '' } })

      expect(form.second_name).to be_nil
    end

    it 'process invalid json schema' do
      user_params = {
        personal_info: { email: 'ivan@example.com' },
        bookmarks:     [{ url: 'http://example.com' }],
        settings:      { timezone: 3, subscriptions: nil },
      }
      form = LooseJsonSchemaForm.new(params: { user: user_params })

      expect(form.personal_info.info(:email)).to include(type: 'string')
      expect(form.bookmarks[0].info(:url)).to include(type: 'string')
      expect(form.info(:settings)).to include(type: 'object')
    end

    context 'when nested form' do
      it 'set single attribute' do
        form = NestedHasOneForm.new
        form.personal_info.age = 18
        form.dimensions.height = 180

        expect(form.personal_info.age).to eq 18
        expect(form.dimensions.height).to eq 180

        form = NestedHasManyForm.new
        form.bookmarks = [{ url: nil }]
        form.favorites = [{ kind: nil }]

        form.bookmarks[0].url = 'https://example.com'
        form.favorites[0].kind = 'book'

        expect(form.bookmarks[0].url).to eq 'https://example.com'
        expect(form.favorites[0].kind).to eq 'book'
      end

      it 'set hash' do
        form = NestedHasOneForm.new
        form.personal_info = { 'age' => 18 }
        form.dimensions = { height: 180 }

        expect(form.personal_info.age).to eq 18
        expect(form.dimensions.height).to eq 180

        form = NestedHasManyForm.new
        form.bookmarks = [{ url: 'https://example.com' }]
        form.favorites = [{ 'kind' => 'book' }]

        expect(form.bookmarks[0].url).to eq 'https://example.com'
        expect(form.favorites[0].kind).to eq 'book'
      end

      it 'set nested hash' do
        form = NestedHasOneForm.new
        form.attributes = { 'personal_info' => { 'age' => 18 }, dimensions: { height: 180 } }

        expect(form.personal_info.age).to eq 18
        expect(form.dimensions.height).to eq 180

        form = NestedHasManyForm.new
        form.attributes = { 'bookmarks' => [{ 'url' => 'https://example.com' }], favorites: [{ kind: 'book' }] }

        expect(form.bookmarks[0].url).to eq 'https://example.com'
        expect(form.favorites[0].kind).to eq 'book'
      end

      it 'merge nested hash' do
        form = NestedHasOneForm.new
        form.dimensions[:height] = 190

        expect(form.dimensions.height).to eq 190

        form = NestedHasManyForm.new
        form.favorites = []
        form.favorites << { kind: 'book' }

        expect(form.favorites[0].kind).to eq 'book'
      end
    end

    context 'when ActionController::Parameters is allowed' do
      it 'read attribute from params' do
        user.update!(second_name: 'Sidorov')
        params = ActionController::Parameters.new(user: { name: 'Ivan', second_name: '' })

        form = UserForm.new(record: user, params: params)

        expect(form.second_name).to be_nil
      end

      it 'set attributes' do
        form = UserForm.new
        form.attributes = ActionController::Parameters.new(name: 'Vasya')
        expect(form.name).to eq 'Vasya'
      end
    end

    context 'when ActionController::Parameters is now allowed' do
      before(:each) { described_class.config.allow_action_controller_parameters = false }

      after(:each) { described_class.reset_config }

      it 'raises error on initialization' do
        expect {
          UserForm.new(params: ActionController::Parameters.new(user: {}))
        }.to raise_error(ActiveDryForm::ParamsNotAllowedError)
      end

      it 'raises error on attributes assignment' do
        form = UserForm.new
        expect {
          form.attributes = ActionController::Parameters.new
        }.to raise_error(ActiveDryForm::ParamsNotAllowedError)
      end
    end
  end

  context 'when param key is not valid' do
    it 'raises error' do
      expect {
        UserForm.new(record: user, params: { form: { name: 'Ivan' } })
      }.to raise_error(ArgumentError, "key 'user' not found in params")
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

    context 'when form validating' do
      it 'returns validation errors' do
        form.validate
        expect(form.valid?).to be false
        expect(form.errors).to eq(name: ['должно быть заполнено'])
      end

      it 'return validation errors after change field' do
        form.validate
        expect(form.valid?).to be false

        form.name = 'Ivan'
        expect(form.valid?).to be false

        form.validate
        expect(form.valid?).to be true
        expect(form.errors).to eq({})
      end
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
      expect(form.errors).to eq({})

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

  context 'when empty fields sent' do
    it 'skips blank values' do
      form = FilterBlankForm.new(params: { form: { name: '', ids: ['', '1'], nested_one: { ids: ['', '2'] }, nested_many: [{ ids: ['', '3'] }] } })

      expect(form.attributes).to eq(
        name:        nil,
        ids:         ['1'],
        nested_one:  { ids: ['2'] },
        nested_many: [{ ids: ['3'] }],
      )

      form.attributes = {
        name:        '',
        ids:         ['', '3'],
        nested_one:  { ids: ['', '4', '5'] },
        nested_many: [{ ids: ['', '6'] }],
      }

      expect(form.attributes).to eq(
        name:        nil,
        ids:         ['3'],
        nested_one:  { ids: %w[4 5] },
        nested_many: [{ ids: ['6'] }],
      )
    end
  end
end
