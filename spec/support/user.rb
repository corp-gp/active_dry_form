# frozen_string_literal: true

User =
  Struct.new(:name, keyword_init: true) do
    def update!(attributes)
      attributes.each do |key, value|
        public_send("#{key}=", value)
      end
    end
  end
