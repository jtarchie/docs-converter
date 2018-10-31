# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/filters/footer'

RSpec.describe 'When filtering footer notes' do
  def filter(content)
    Docs::Filters::Footer.new(
        content: content,
        path: nil,
        config: nil
    ).process
  end

  it 'footer links from html to md' do
    content = filter(%([a]: testing.html))
    expect(content).to eq '[a]: testing.md'
  end

  it 'ignores footer comments' do
    # this is a pattern used in docs because Markdown does not support comments
    content = filter('[//]: # (Comment: Below calls vars concept_product_* in book repository template_vars.yml.)')
    expect(content).to eq '[//]: # (Comment: Below calls vars concept_product_* in book repository template_vars.yml.)'
  end
end
