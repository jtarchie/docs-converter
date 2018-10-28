# frozen_string_literal: true

module Docs
  module Filters
    class Footer
      FOOTER_LINKS_REGEX = /^\[.*?\]:\s+(.*?)$/

      def initialize(content:, path:, config:)
        @content = content
      end

      def process
        @content.gsub(FOOTER_LINKS_REGEX) do |match|
          if URI.parse(match.match(FOOTER_LINKS_REGEX)[1]).relative?
            match.gsub('.html', '.md')
          else
            match
          end
        end
      end
    end
  end
end
