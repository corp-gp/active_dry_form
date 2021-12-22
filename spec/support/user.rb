# frozen_string_literal: true

class User < Struct.new(:name, keyword_init: true)
  def update!(attributes)
    attributes.each do |key, value|
      public_send("#{key}=", value)
    end
  end
end

