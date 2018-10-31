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
          uri = match.match(FOOTER_LINKS_REGEX)[1]
          return match if uri.start_with?('#')

          if URI.parse(uri).relative?
            match.gsub('.html', '.md')
          else
            match
          end
        end
      end
    end
  end
end
