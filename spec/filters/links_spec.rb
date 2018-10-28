# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/filters/links'

RSpec.describe 'When filtering links' do
  it 'handles multiple links on the same line' do
    filter = Docs::Filters::Links.new(
      path: nil,
      config: nil,
      content: 'and how to [activate apps](#activate-apps). see [Modifying Apps](modify-apps-tls.html).'
    )
    content = filter.process
    expect(content).to eq 'and how to [activate apps](#activate-apps). see [Modifying Apps](modify-apps-tls.md).'
  end

  it 'handles multiple lines' do
    filter = Docs::Filters::Links.new(
      path: nil,
      config: nil,
      content: "[a](testing.html#something) or [b](http://example.com/index.html) or\n[c]: ./c.html\n[d]: ./d.html"
    )
    content = filter.process
    expect(content).to eq "[a](testing.md#something) or [b](http://example.com/index.html) or\n[c]: ./c.md\n[d]: ./d.md"
  end

  it 'handles html appearing in the link name' do
    filter = Docs::Filters::Links.new(
      path: nil,
      config: nil,
      content: '[index.html](index.html)'
    )
    content = filter.process
    expect(content).to eq '[index.html](index.md)'
  end

  it 'handles unicode characters in the link' do
    filter = Docs::Filters::Links.new(
      path: nil,
      config: nil,
      content: "[feedback](mailto:admin\u2013feedback@example.com)"
    )
    content = filter.process
    expect(content).to eq "[feedback](mailto:admin\u2013feedback@example.com)"
  end
end
