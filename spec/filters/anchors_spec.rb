# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/filters/anchor'

RSpec.describe 'When filtering anchors' do
  def filter(content)
    filter = Docs::Filters::Anchor.new(
      path: nil,
      config: nil,
      content: content
    )
    filter.process
  end

  it 'does not parse anchors not in headers' do
    [
      %(<a id="testing">testing</a>),
      %(<a id="testing"></a> testing)
    ].each do |content|
      expect(filter(content)).to eq content
    end
  end

  it 'does parses anchors in headers' do
    expect(filter(%(# <a id="testing"></a> testing))).to eq '# testing'
    expect(filter(%(## <a id="testing"></a> testing))).to eq '## testing'
    expect(filter(%(# <a id="testing">testing</a>))).to eq '# testing'
    expect(filter(%(## <a id="testing">testing</a>))).to eq '## testing'
  end
end
