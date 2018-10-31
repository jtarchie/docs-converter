# frozen_string_literal: true

module Docs
  module Filters
    class ImageTag
      IMAGE_REGEX = /<%=\s+image_tag\(?\s*['"](.*)['"]\)?\s*%>/i

      def initialize(content:, path:, config:)
        @content = content
      end

      def process
        @content.gsub(IMAGE_REGEX) do |match|
          matches = match.match(IMAGE_REGEX)
          "<img src=\"#{matches[1]}\">"
        end
      end
    end
  end
end
