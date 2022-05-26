# frozen_string_literal: true

RSpec::Matchers.define :include_html do |expected|
  def clean_html(html)
    html.gsub(/>\s+</, '><').strip
  end

  match do |actual|
    clean_html(actual).include?(clean_html(expected))
  end
end
