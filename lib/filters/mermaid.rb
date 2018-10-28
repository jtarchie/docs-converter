# frozen_string_literal: true

module Docs
  module Filters
    class Mermaid
      MERMAID_REGEX = /<%\s+mermaid_diagram\s+do\s+%>(.*?)<%\s+end\s+%>/m

      def initialize(content:, path:, config:)
        @content = content
      end

      def process
        @content.gsub(MERMAID_REGEX) do |match|
          mermaid_diagram = match.match(MERMAID_REGEX)[1]
          ['<div class="mermaid">', mermaid_diagram.strip, '</div>'].join("\n")
        end
      end
    end
  end
end
