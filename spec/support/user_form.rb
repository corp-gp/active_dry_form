# frozen_string_literal: true

class UserForm < ActiveDryForm::Form

  fields(:user) do
    params do
      required(:name).filled(:string)
    end

    rule(:name) do |context:|
      form = context[:form]
      if form.record.name == 'Ivan' && values[:name] == 'Maria'
        key(:name).failure(:ivan_cant_be_maria)
      end
    end
  end

  action def update
    record.update!(validator.to_h)
    Success(record)
  end

end
