# frozen_string_literal: true

require 'pp'
require 'fakefs/spec_helpers'
require 'spec_helper'
require 'tmpdir'
require_relative '../../lib/filters/partial'

RSpec.describe 'Converts partials to jinja includes' do
  include FakeFS::SpecHelpers

  let(:dir) { Dir.mktmpdir }

  def create_file(basename)
    path = File.join(dir, basename)
    File.write(path, '')
    path
  end

  def filter(contents)
    File.write(
      path = create_file('index.md'),
      contents
    )

    Docs::Filters::Partial.new(
      content: contents,
      path: path,
      config: nil
    )
  end

  it 'handles partials with _ prefixing' do
    create_file('_something')
    f = filter('<%= partial "something" %>')
    expect(f.process).to match /\{% include "_something.*" %}/
  end

  it 'handles partials with no prefixing' do
    create_file('something')
    f = filter('<%= partial "something" %>')
    expect(f.process).to match /\{% include "something.*" %}/
  end

  it 'converts html to md' do
    create_file('something.html')
    f = filter('<%= partial "something" %>')
    expect(f.process).to match /\{% include "something.md" %}/
  end

  it 'handles partials that do not exit' do
    f = filter('<%= partial "../something" %>')
    expect(f.process).to match /\{% include "\.\.\/something" %}/
  end

  it 'does nothing when an extension is specified' do
    create_file('something.txt')
    f = filter('<%= partial "something.txt" %>')
    expect(f.process).to match /\{% include "something.txt" %}/
  end
end
