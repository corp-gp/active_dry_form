# frozen_string_literal: true

RSpec.describe ActiveDryForm::Form do
  include Dry::Monads[:result]

  let(:form_class) do
    Class.new(described_class) do
      fields(:example) { params { required(:name).filled(:string) } }

      action def submit(result:)
        Success(result.value!)
      end

      action def explicit_success
        Success(:created)
      end

      action def explicit_failure
        Failure(['Invalid captcha'])
      end

      action def plain_value
        :created
      end
    end
  end
  let(:form) { form_class.new(params: { name: 'Ivan' }) }

  it 'returns the original Failure and adds its error to base_errors' do
    failure = Failure('Invalid captcha')

    expect(form.submit(result: failure)).to equal(failure)
    expect(form.base_errors).to eq(['Invalid captcha'])
  end

  it 'converts symbol failure into string base_errors' do
    failure = Failure(:invalid_captcha)

    expect(form.submit(result: failure)).to equal(failure)
    expect(form.base_errors).to eq(['invalid_captcha'])
  end

  it 'preserves all errors when the unwrapped Failure contains an array' do
    failure = Failure(['Invalid captcha', 'Try again'])

    expect(form.submit(result: failure)).to equal(failure)
    expect(form.base_errors).to eq(['Invalid captcha', 'Try again'])
  end

  it 'continues the action after unwrapping a Success' do
    expect(form.submit(result: Success(:created))).to eq(Success(:created))
    expect(form.base_errors).to eq([])
  end

  it 'propagates exceptions raised by a service' do
    service = double(:service)
    allow(service).to receive(:value!).and_raise(RuntimeError, 'Service crashed')

    expect { form.submit(result: service) }.to raise_error(RuntimeError, 'Service crashed')
  end

  it 'handles an explicitly returned Failure in the same way' do
    expect(form.explicit_failure).to eq(Failure(['Invalid captcha']))
    expect(form.base_errors).to eq(['Invalid captcha'])
  end

  it 'handles an explicitly returned Success' do
    expect(form.explicit_success).to eq(Success(:created))
    expect(form.base_errors).to eq([])
  end

  it 'raises ResultError when the action returns a plain value' do
    expect { form.plain_value }
      .to raise_error(described_class::ResultError, 'method `plain_value` must return `monad`')
  end

  it 'returns Failure(:invalid_form) and skips the action when the form is invalid' do
    invalid_form = form_class.new(params: { name: '' })

    expect(invalid_form.submit(result: Failure('Invalid captcha'))).to eq(Failure(:invalid_form))
    expect(invalid_form.base_errors).to eq([])
  end
end
