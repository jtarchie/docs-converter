require 'fileutils'
require 'securerandom'
require 'spec_helper'
require 'tmpdir'

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

  def convert_docs
    Docs::Convert.new(
      source_dir: source_dir,
      output_dir: output_dir
    ).execute!
  end

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

  it 'converts html links to md' do
    doc = create_doc '[testing](testing.html#something)'
    expect(convert_docs).to be_falsy

    expect(doc.contents).to eq '[testing](testing.md#something)'
    File.write(File.join(source_dir, 'testing.html.md.erb'), 'testing')
    expect(convert_docs).to be_truthy
  end
end
