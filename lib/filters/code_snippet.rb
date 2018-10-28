# frozen_string_literal: true

module Docs
  module Filters
    class CodeSnippet
      CODE_SNIPPET_REGEX = /<%=\s+yield_for_code_snippet\s+from:\s*['"](.*?)['"].*at:\s*['"](.*?)['"].*?%>/i

      def initialize(content:, path:, config:)
        @content = content
        @config = config
      end

      def process
        @dependent_sections ||= {}
        content = @content.gsub(CODE_SNIPPET_REGEX) do |match|
          _, from, at = *match.match(CODE_SNIPPET_REGEX)
          @dependent_sections[from] = File.join('..', from.split('/').last)
          "{% code_snippet '#{from}', '#{at}' %}"
        end
        plugin = @config['plugins']['jinja2'] || {}
        plugin['dependent_sections'] ||= {}
        plugin['dependent_sections'].merge!(@dependent_sections)
        @config['plugins']['jinja2'] = plugin

        content
      end
    end
  end
end
