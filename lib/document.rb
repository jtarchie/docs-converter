# frozen_string_literal: true

Dir[File.join(__dir__, 'filters', '*.rb')].each { |f| require_relative f }

module Docs
  Document = Struct.new(:path, :config, :source_dir, :output_dir, keyword_init: true) do
    attr_reader :dependent_sections

    def write!
      @dependent_sections ||= {}
      warn "Converting #{path} => #{new_path}"
      new_contents = [Filters::Alerts, Filters::Anchor, Filters::CodeSnippet, Filters::Footer,
                      Filters::Links, Filters::Mermaid, Filters::Partial].inject(contents) do |content, filter|
        filter.new(
          content: content,
          path: path,
          config: config
        ).process
      end
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
