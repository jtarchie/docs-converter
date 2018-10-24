# frozen_string_literal: true

require 'fileutils'
require 'nokogiri'
require 'yaml'

module Docs
  Convert = Struct.new(:source_dir, :output_dir, :sitemap_path, keyword_init: true) do
    def execute!
      system("mkdocs new #{output_dir}")
      dependent_sections = {}
      Dir[File.join(source_dir, '**', '*')].each do |filename|
        next if File.directory?(filename)

        doc = Document.new(
          path: filename,
          source_dir: source_dir,
          output_dir: output_dir
        )
        doc.write!

        dependent_sections.merge!(doc.dependent_sections)
      end
      write_mkdocs_config(dependent_sections: dependent_sections)
      write_requirements
      Dir.chdir(output_dir) do
        system('pip install -r requirements.txt')
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

    def write_mkdocs_config(dependent_sections: {})
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
      (config['plugins'] ||= []).push({ 'jinja2' => {
                                        'dependent_sections' => dependent_sections
                                      } }, 'search').uniq!
      (config['markdown_extensions'] ||= [])
        .push('codehilite')
        .push('admonition')
        .uniq!
      (config['extra_javascript'] ||= []).push('https://cdnjs.cloudflare.com/ajax/libs/mermaid/7.1.2/mermaid.min.js').uniq!
      config['nav'] = generate_nav
      File.write(config_file, "# Example: https://github.com/squidfunk/mkdocs-material/blob/master/mkdocs.yml\n" + YAML.dump(config))
    end

    def generate_nav
      return [] unless sitemap_path

      site_links = Nokogiri::HTML(File.read(sitemap_path)).css('ul li a')
      site_links.map do |link|
        name = link.text
        uri  = File.basename(link['href']).gsub('.html', '.md').to_s
        { name => uri }
      end
    end
  end

  Document = Struct.new(:path, :source_dir, :output_dir, keyword_init: true) do
    attr_reader :dependent_sections

    MERMAID_REGEX = /<%\s+mermaid_diagram\s+do\s+%>(.*?)<%\s+end\s+%>/m
    LINKS_REGEX = /(\(.*?\.html.*?\))/
    FOOTER_LINKS_REGEX = /^\[.*?\]:\s+(.*?)$/
    PARTIAL_REGEX = /<%=\s+partial\s+['"].*?['"]\s+%>/i
    ANCHOR_REGEX = %r{<a\s+id\s*=\s*.*?>.*?</a>}i
    CODE_SNIPPET_REGEX = /<%=\s+yield_for_code_snippet\s+from:\s*['"](.*?)['"].*at:\s*['"](.*?)['"].*?%>/i
    ALERTS_REGEX = /<p\s+class=['"](.*?)['"]>(.*?)<\/p>/im

    def write!
      @dependent_sections ||= {}
      warn "Converting #{path} => #{new_path}"
      new_contents = contents
                     .gsub(ANCHOR_REGEX, '')
                     .gsub(MERMAID_REGEX, &method(:cleanup_mermaid))
                     .gsub(FOOTER_LINKS_REGEX, &method(:cleanup_footer))
                     .gsub(LINKS_REGEX, &method(:cleanup_links))
                     .gsub(PARTIAL_REGEX, &method(:cleanup_partials))
                     .gsub(CODE_SNIPPET_REGEX, &method(:cleanup_code_snippet))
                     .gsub(ALERTS_REGEX, &method(:cleanup_alerts))
      warn_erb new_contents
      FileUtils.mkdir_p(File.dirname(new_path))
      File.write(new_path, new_contents)
    end

    def contents
      @contents ||= File.read(path)
    end

    def new_path
      relative = File.dirname(path).gsub(source_dir.chomp('/'), '')
      @new_path ||= File.join(
        output_dir, 'docs', relative, File.basename(path)
      )
                        .gsub('.html.md.erb', '.md')
                        .gsub('.mmd.erb', '.mmd')
    end

    private

    def cleanup_alerts(match)
      _, classes, content = *match.match(ALERTS_REGEX)
      return "!!! warning\n    #{content}\n\n" if classes.include?('warning')

      "!!! note\n    #{content}\n\n"
    end

    def cleanup_code_snippet(match)
      _, from, at = *match.match(CODE_SNIPPET_REGEX)
      @dependent_sections[from] = File.join('..', from.split('/').last)
      "{% code_snippet '#{from}', '#{at}' %}"
    end

    def cleanup_partials(match)
      filename = match.match(/['"](.*?)['"]/)[1]
      partial_path = [
        File.join(File.dirname(filename), "_#{File.basename filename}"),
        File.join(File.dirname(filename), (File.basename filename).to_s)
      ].find do |p|
        !Dir[File.join(File.dirname(path), "#{p}*")].empty?
      end

      if filename.include?('.')
        %({% include "#{partial_path}" %})
      else
        %({% include "#{partial_path}.md" %})
      end
    end

    def cleanup_links(match)
      if URI.parse(match[1..-2]).relative?
        match.gsub('.html', '.md')
      else
        match
      end
    end

    def cleanup_mermaid(match)
      mermaid_diagram = match.match(MERMAID_REGEX)[1]
      ['<div class="mermaid">', mermaid_diagram.strip, '</div>'].join("\n")
    end

    def cleanup_footer(match)
      if URI.parse(match.match(FOOTER_LINKS_REGEX)[1]).relative?
        match.gsub('.html', '.md')
      else
        match
      end
    end

    def warn_erb(contents)
      return unless contents.include?('<%')

      contents.lines.each_with_index do |line, num|
        if line.include? '<%'
          warn "WARNING: ERB found in #{path} at line #{num + 1}"
        end
      end
    end
  end
end
