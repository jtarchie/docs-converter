# frozen_string_literal: true

module Docs
  module Filters
    class Links
      LINKS_REGEX = /(\(.*?\.html.*?\))/

      def initialize(content:, path:, config:)
        @content = content
      end

      def process
        @content.gsub(LINKS_REGEX) do |match|
          if URI.parse(match[1..-2]).relative?
            match.gsub('.html', '.md')
          else
            match
          end
        end
      end
    end
  end
end
