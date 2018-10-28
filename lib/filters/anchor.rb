# frozen_string_literal: true

module Docs
  module Filters
    class Anchor
      ANCHOR_REGEX = %r{<a\s+id\s*=\s*.*?>.*?</a>}i

      def initialize(content:, path:, config:)
        @content = content
      end

      def process
        @content.gsub(ANCHOR_REGEX, '')
      end
    end
  end
end
