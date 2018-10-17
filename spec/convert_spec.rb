# frozen_string_literal: true

require 'fileutils'
require 'securerandom'
require 'spec_helper'
require 'tempfile'
require 'tmpdir'
require 'yaml'

RSpec.describe 'when running the converter' do
  let(:source_dir) { Dir.mktmpdir }
  let(:output_dir) { Dir.mktmpdir }

  Document = Struct.new(:path, :source_dir, :output_dir, keyword_init: true) do
    def new_path
      relative = File.dirname(path).gsub(source_dir, '')
      extension = '.' + File.basename(path).split('.')[1..-1].join('.')
      base_name = File.basename(path, extension)
      new_extension = {
        '.html.md.erb' => '.md'
      }.fetch(extension)
      File.join(output_dir, 'docs', relative, "#{base_name}#{new_extension}")
    end

    def contents
      File.read(new_path)
    end
  end

  def create_doc(contents, extension = '.html.md.erb')
    path = File.join(source_dir, "#{SecureRandom.hex}#{extension}")
    File.write(path, contents)
    Document.new(
      path: path,
      source_dir: source_dir,
      output_dir: output_dir
    )
  end

  def create_partial(name, extension = '.html.md.erb')
    path = File.join(source_dir, "#{name}#{extension}")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, 'testing')
    Document.new(
      path: path,
      source_dir: source_dir,
      output_dir: output_dir
    )
  end

  def convert_docs(sitemap_path: nil)
    Docs::Convert.new(
      source_dir: source_dir,
      output_dir: output_dir,
      sitemap_path: sitemap_path
    ).execute!
  end

  context 'with markdown docs' do
    it 'handles removings a[id]' do
      doc = create_doc '#<a id="testing"></a> testing'
      expect(convert_docs).to be_truthy

      expect(doc.contents).to eq '# testing'
      expect(File.exist?(doc.new_path)).to be_truthy
    end

    it 'converts partials to {%include%}' do
      doc = create_doc '<%= partial "testing/some_file" %>'
      partial = create_partial 'testing/_some_file'
      expect(convert_docs).to be_truthy

      expect(doc.contents).to eq '{% include "testing/_some_file.md" %}'
      expect(File.exist?(partial.new_path)).to be_truthy
    end

    it 'converts relative html links to relative md' do
      doc = create_doc '[a](testing.html#something) or [b](http://example.com/index.html)'
      expect(convert_docs).to be_falsy

      expect(doc.contents).to eq '[a](testing.md#something) or [b](http://example.com/index.html)'
      File.write(File.join(source_dir, 'testing.html.md.erb'), 'testing')
      expect(convert_docs).to be_truthy
    end
  end

  context 'with the mkdocs.yml' do
    let(:config) { YAML.load_file File.join(output_dir, 'mkdocs.yml') }
    let(:requirements) { File.read File.join(output_dir, 'requirements.txt') }

    it 'uses material view' do
      expect(convert_docs).to be_truthy
      expect(config['theme']).to eq 'material'
      expect(requirements).to include 'mkdocs-material'

      expect(config['strict']).to eq true
      expect(config['use_directory_urls']).to eq false
    end

    it 'has allows syntax highlighting like github' do
      expect(convert_docs).to be_truthy
      expect(requirements).to include 'pygments'
      expect(config['markdown_extensions']).to include 'codehilite'
    end

    it 'converts the original site map (if provided)' do
      sitemap = Tempfile.new('sitemap')
      sitemap.write(<<-HTML)
      <ul>
        <li><a href="doc1.html">Document 1</a></li>
        <li><a href="doc2.md">Document 2</a></li>
        <li><a href="doc3.md">Document 3</a></li>
      </ul>
      HTML
      sitemap.close

      convert_docs(sitemap_path: sitemap.path)
      expect(config['nav']).to eq [
        { 'Document 1' => 'doc1.md' },
        { 'Document 2' => 'doc2.md' },
        { 'Document 3' => 'doc3.md' }
      ]
    end
  end
end
