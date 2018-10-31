# frozen_string_literal: true

require 'fileutils'
require 'nokogiri'
require 'yaml'
require_relative 'document'
require_relative 'nav_generator'

module Docs
  Convert = Struct.new(:source_dir, :output_dir, :sitemap_path, keyword_init: true) do
    def execute!
      system("mkdocs new #{output_dir}")
      config = read_config

      system("rsync -av --exclude='.[!.]*' #{source_dir}/ #{File.join(output_dir, 'docs')}")

      Dir.glob([
                 File.join(output_dir, '**', '*.html.md.erb'),
                 File.join(output_dir, '**', '*.mmd.erb')
               ]).each do |filename|
        doc = Document.new(
          path: filename,
          config: config
        )
        doc.write!
        File.unlink(filename)
      end
      write_mkdocs_config(config)
      write_requirements
      Dir.chdir(output_dir) do
        system('pip3 install -r requirements.txt')
        system('mkdocs build -s')
      end
    end

    private

    def write_requirements
      requirements_file = File.join(output_dir, 'requirements.txt')
      File.write(requirements_file, [
        'mkdocs',
        'mkdocs-material',
        'pygments',
        'git+https://github.com/jtarchie/docs-converter.git#egg=mkdocs-jinja2&subdirectory=mkdocs-plugins/mkdocs-jinja2'
      ].join("\n"))
    end

    def read_config
      config_file = File.join(output_dir, 'mkdocs.yml')
      config = YAML.load_file config_file
      config['theme'] = {
        'logo' => 'https://docs.pivotal.io/images/icon-p-green.jpg',
        'name' => 'material',
        'font' => { 'code' => 'Ubuntu Mono', 'text' => 'Source Sans Pro' },
        'palette' => { 'accent' => 'teal', 'primary' => 'teal' }
      }
      config['strict'] = true
      config['use_directory_urls'] = false
      config['plugins'] = {
        'search' => {},
        'jinja2' => {}
      }
      (config['markdown_extensions'] ||= [])
        .push('codehilite')
        .push('admonition')
        .uniq!
      (config['extra_javascript'] ||= []).push('https://cdnjs.cloudflare.com/ajax/libs/mermaid/7.1.2/mermaid.min.js').uniq!
      config['nav'] = generate_nav
      config
    end

    def write_mkdocs_config(config)
      config_file = File.join(output_dir, 'mkdocs.yml')
      config['plugins'] = config['plugins'].map do |key, value|
        { key => value }
      end
      File.write(config_file, "# Example: https://github.com/squidfunk/mkdocs-material/blob/master/mkdocs.yml\n" + YAML.dump(config))
    end

    def generate_nav
      NavGenerator.new(path: sitemap_path).to_hash
    end
  end
end
