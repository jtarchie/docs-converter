# frozen_string_literal: true

module Docs
  module Filters
    class Links
      LINKS_REGEX = /\[(.*?)\]\((.*?)\)/
      FOOTER_LINKS_REGEX = /^\[(.*?)\]: (.*)/

      def initialize(content:, path:, config:)
        @content = content
      end

      def process
        @content.gsub(LINKS_REGEX) do |match|
          matches = match.match(LINKS_REGEX).to_a
          if URI.parse(matches[2]).relative?
            "[#{matches[1]}](#{matches[2].gsub('.html', '.md')})"
          else
            match
          end
        rescue
          match
        end.gsub(FOOTER_LINKS_REGEX) do |match|
          matches = match.match(FOOTER_LINKS_REGEX).to_a
          if URI.parse(matches[2]).relative?
            "[#{matches[1]}]: #{matches[2].gsub('.html', '.md')}"
          else
            match
          end
        rescue
          match
        end
      end
    end
  end
end
