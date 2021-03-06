# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/convert'
require 'tmpdir'

RSpec.describe 'mkdocs plugins' do
  let(:output_dir) { Dir.mktmpdir }
  let(:docs_dir) { File.join(output_dir, 'docs') }
  let(:site_dir) { File.join(output_dir, 'site') }
  let(:plugin_dir) { File.expand_path(File.join(__dir__, '..', 'mkdocs-plugins', 'mkdocs-jinja2')) }

  context 'with jinja2 support' do
    def create_docs(additional_config = {})
      system("mkdocs new #{output_dir}")
      File.write(File.join(output_dir, 'requirements.txt'), <<-REQUIREMENTS)
      file://#{plugin_dir}?egg=mkdocs-jinja2")
      pyramid_jinja2
      REQUIREMENTS
      config_file = File.join(output_dir, 'mkdocs.yml')
      config = YAML.load_file(config_file)
      config['plugins'] ||= [{ 'jinja2' => additional_config }]
      config['use_directory_urls'] = false
      File.write(config_file, YAML.dump(config))
    end

    def create_site
      Dir.chdir(output_dir) do
        system('cat mkdocs.yml')
        system('cat requirements.txt')
        system('pip3 uninstall --yes mkdocs-jinja2')
        system('pip3 install -r requirements.txt')
        system('mkdocs build')
      end
    end

    def write_doc(name, contents)
      path = File.join(docs_dir, name)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, contents)
    end

    def read_doc(name)
      File.read(File.join(site_dir, name))
    end

    it 'supports includes using the file system docs/ as the base lookup path' do
      create_docs

      write_doc 'test.md', "a header: {% include 'header1.md' %}"
      write_doc 'header1.md', 'appears'

      write_doc 'testing/test.md', "a header: {% include 'header.md' %}"
      write_doc 'testing/header.md', 'appears again'

      create_site

      expect(read_doc('test.html')).to include 'a header: appears'
      expect(read_doc('testing/test.html')).to include 'a header: appears again'
    end

    context 'with code snippets' do
      let(:repo_dir) { Dir.mktmpdir }

      it 'supports code snippets from another directory' do
        create_docs(
          'dependent_sections' => {
            'repo-name' => repo_dir
          }
        )

        Dir.chdir(repo_dir) do
          system('git init')
          File.write('testing.go', <<~SNIPPET)
            # code_snippet snippet-name start yaml
            some: yaml
            # code_snippet snippet-name end
          SNIPPET
          system('git add -A && git commit -mok')
        end

        write_doc 'test.md', "code here: {% code_snippet 'repo-name', 'snippet-name' %}\nsome extra copy to ensure newlines"
        create_site

        expect(read_doc('test.html')).to include(%Q{\n<pre><code class="yaml">some: yaml\n</code></pre>\n\n})
      end
    end
  end
end
