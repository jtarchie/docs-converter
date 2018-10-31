# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require_relative '../lib/nav_generator'

RSpec.describe 'When generating a nav' do
  let(:nav_file) { Tempfile.new }

  def create_nav(nav)
    html = '<ul>' + nav.map { |href, name| "<li><a href='#{href}'>#{name}</a></li>" }.join('') + '</ul>'
    File.write(nav_file, html)
    Docs::NavGenerator.new(path: nav_file).to_hash
  end

  it 'converts html to md' do
    nav = create_nav([
                       ['doc1.html', 'Document exists'],
                       ['doc2.html', 'Document does not exist']
                     ])

    expect(nav).to eq([
                        { 'Document exists' => 'doc1.md' },
                        { 'Document does not exist' => 'doc2.md' }
                      ])
  end

  it 'handles navigation with sub-sub-menus' do
    File.write(nav_file, File.read(File.join(__dir__, 'fixtures/deepnav.html')))
    nav = Docs::NavGenerator.new(path: nav_file).to_hash

    expect(nav).to eq([
                        { 'Home' => 'index.md' },
                        { 'Using' => 'using.md' },
                        { 'API' => [
                          { 'Home' => 'api/index.md' },
                          { 'Config' => 'api/config.md' },
                          { 'Auth' => 'api/auth.md' }
                        ] },
                        { 'Release Notes' => 'release-notes.md' }
                      ])
  end
end
