# frozen_string_literal: true

module Docs
  module Filters
    class Alerts
      ALERTS_REGEX = /\s*<p\s+class=['"](.*?)['"]>(.*?)<\/p>\s*/im

      def initialize(content:, path:, config:)
        @content = content
      end

      def process
        @content.gsub(ALERTS_REGEX) do |match|
          _, classes, content = *match.match(ALERTS_REGEX)
          content = content.gsub(/\s+/, ' ').split("\n").join("\n    ")
          classes = classes.split(/\s+/)
          classes.delete('note')
          "\n\n!!! #{classes.last || 'note'} \"\"\n    #{content}\n\n"
        end
      end
    end
  end
end
