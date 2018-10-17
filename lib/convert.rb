require 'fileutils'

module Docs
  Convert = Struct.new(:source_dir, :output_dir, keyword_init: true) do
    def execute!
      system("mkdocs new #{output_dir}")
      Dir[File.join(source_dir, '*.html.md.erb')].each do |filename|
        Document.new(
          path: filename,
          source_dir: source_dir,
          output_dir: output_dir
        ).write!
      end
      Dir.chdir(output_dir) do
        system('mkdocs build -s')
      end
    end
  end

  Document = Struct.new(:path, :source_dir, :output_dir, keyword_init: true) do
    def write!
      warn "Converting #{path} => #{new_path}"
      new_contents = contents
                     .gsub(%r{<a\s+id\s*=\s*.*?>.*?</a>}i, '')
                     .gsub('.html', '.md')
                     .gsub(/<%=\s+partial\s+['"].*?['"]\s+%>/i) do |match|
        filename = match.match(/['"](.*?)['"]/)[1]
        partial_path = File.join(File.dirname(filename), "_#{File.basename filename}")
        Document.new(
          path: File.join(File.dirname(path), "#{partial_path}.html.md.erb"),
          source_dir: source_dir,
          output_dir: output_dir
        ).write!
        %({% include "#{partial_path}.md" %})
      end
      FileUtils.mkdir_p(File.dirname(new_path))
      File.write(new_path, new_contents)
    end

    def contents
      @contents ||= File.read(path)
    end

    def new_path
      relative = File.dirname(path).gsub(source_dir, '')
      @new_path ||= File.join(
        output_dir, 'docs', relative, File.basename(path)
      ).gsub!('.html.md.erb', '.md')
    end
  end
end
