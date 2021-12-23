# frozen_string_literal: true

class CustomValidationForm < UserForm

  fields(:user) do
    params do
      optional(:name).maybe(:string)
    end

    rule(:name) do |context:|
      form = context[:form]
      if form.record.name == 'Ivan' && values[:name] == 'Maria'
        key(:name).failure(:ivan_cant_be_maria)
      end
    end
  end

end
