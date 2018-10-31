# frozen_string_literal: true

module Docs
  module Filters
    class Anchor
      ANCHOR_REGEX = %r{^(#+)\s*<a\s+id\s*=\s*.*?>(.*?)</a>\s*}i

      def initialize(content:, path:, config:)
        @content = content
      end

      def process
        @content.gsub(ANCHOR_REGEX) do |match|
          matches = match.match(ANCHOR_REGEX)
          "#{matches[1]} #{matches[2]}"
        end
      end
    end
  end
end
