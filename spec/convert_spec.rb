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
  let(:config) { YAML.load_file File.join(output_dir, 'mkdocs.yml') }

  Document = Struct.new(:path, :source_dir, :output_dir, keyword_init: true) do
    def new_path
      relative = File.dirname(path).gsub(source_dir, '')
      extension = '.' + File.basename(path).split('.')[1..-1].join('.')
      base_name = File.basename(path, extension)
      new_extension = {
        '.html.md.erb' => '.md',
        '.mmd.erb' => '.mmd'
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
    system('pip uninstall --yes mkdocs-jinja2')
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
      doc1 = create_doc '<%= partial "testing/some_file" %>'
      doc2 = create_doc '<%= partial "testing/_some_file" %>'
      partial = create_partial 'testing/_some_file'
      expect(convert_docs).to be_truthy

      expect(doc1.contents).to eq '{% include "testing/_some_file.md" %}'
      expect(doc2.contents).to eq '{% include "testing/_some_file.md" %}'
      expect(File.exist?(partial.new_path)).to be_truthy
    end

    it 'converts partials that do not have an underscore' do
      doc = create_doc '<%= partial "testing/some_file" %>'
      partial = create_partial 'testing/some_file'
      expect(convert_docs).to be_truthy

      expect(doc.contents).to eq '{% include "testing/some_file.md" %}'
      expect(File.exist?(partial.new_path)).to be_truthy
    end

    it 'converts relative html links to relative md' do
      doc = create_doc "[a](testing.html#something) or [b](http://example.com/index.html) or\n[c]: ./c.html"
      expect(convert_docs).to be_falsy

      expect(doc.contents).to eq "[a](testing.md#something) or [b](http://example.com/index.html) or\n[c]: ./c.md"
      File.write(File.join(source_dir, 'testing.html.md.erb'), 'testing')
      expect(convert_docs).to be_truthy
    end

    it 'gives a warning if unsupported ERB is present' do
      doc = create_doc "<%= 'Line 1' %>\n# testing\n<%= '3' %>"
      expect { convert_docs }.to output(/WARNING: ERB found in #{doc.path} at line 1/).to_stderr
    end

    it 'converts mermaid documents to a div.mermaid' do
      doc = create_doc(
        "<% mermaid_diagram do %>\nsome mermaid stuff\n<% end %>",
        '.mmd.erb'
      )
      expect(convert_docs).to be_truthy
      expect(doc.contents).to eq "<div class=\"mermaid\">\nsome mermaid stuff\n</div>"
      expect(config['extra_javascript']).to include /mermaid.min.js/
    end

    it 'converts code snippets to use the correct jinja extension' do
      repo_dir = File.expand_path(File.join(File.dirname(output_dir), 'repo'))
      FileUtils.mkdir_p(repo_dir)
      Dir.chdir(repo_dir) do
        system('git init')
        File.write('testing.go', <<~SNIPPET)
          # code_snippet snippet-name start yaml
          some: yaml
          # code_snippet snippet-name end
        SNIPPET
        system('git add -A && git commit -mok')
      end

      doc = create_doc 'code: <%= yield_for_code_snippet from: "org/repo", at: "snippet-name" %>'
      expect(convert_docs).to be_truthy
      expect(config['plugins'].first['jinja2']['dependent_sections']).to include('org/repo' => '../repo')
      expect(doc.contents).to eq "code: {% code_snippet 'org/repo', 'snippet-name' %}"
    end
  end

  context 'with the mkdocs.yml' do
    let(:requirements) { File.read File.join(output_dir, 'requirements.txt') }

    it 'uses material view and sane defaults' do
      expect(convert_docs).to be_truthy
      expect(config['theme']).to eq 'material'
      expect(requirements).to include 'mkdocs-material'

      expect(config['strict']).to eq true
      expect(config['use_directory_urls']).to eq false

      expect(config['plugins']).to include('jinja2' => { 'dependent_sections' => {} })
      expect(requirements).to include 'git+https://github.com/jtarchie/docs-converter.git#egg=mkdocs-jinja2&subdirectory=mkdocs-plugins/mkdocs-jinja2'
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
