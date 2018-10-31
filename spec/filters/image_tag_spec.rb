# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/filters/image_tag'

RSpec.describe 'When filtering image_tag' do
  def filter(content)
    Docs::Filters::ImageTag.new(
      content: content,
      path: nil,
      config: nil
    ).process
  end
  it 'converts image_tag with just a path' do
    content = filter(%(<%= image_tag "some_image.png" %>))
    expect(content).to eq '<img src="some_image.png">'
    content = filter(%(<%= image_tag("some_image.png") %>))
    expect(content).to eq '<img src="some_image.png">'
  end

  it 'supports single quotes' do
    content = filter(%(<%= image_tag 'some_image.png' %>))
    expect(content).to eq '<img src="some_image.png">'
    content = filter(%(<%= image_tag('some_image.png') %>))
    expect(content).to eq '<img src="some_image.png">'
  end
end
