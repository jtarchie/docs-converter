# frozen_string_literal: true

module Docs
  module Filters
    class Partial
      PARTIAL_REGEX = /<%=\s+partial\s+['"](.*?)['"]\s+%>/i

      def initialize(content:, path:, config:)
        @content = content
        @path = path
      end

      def process
        @content.gsub(PARTIAL_REGEX) do |match|
          filename = match.match(PARTIAL_REGEX)[1]
          partial_path = [
            File.join(File.dirname(filename), "_#{File.basename filename}"),
            File.join(File.dirname(filename), (File.basename filename).to_s)
          ].find do |p|
            !Dir[File.join(File.dirname(@path), "#{p}*")].empty?
          end

          if partial_path
            partial_path.gsub!(/^\.+\//, '')

            if filename.include?('.')
              %({% include "#{partial_path}" %})
            else
              %({% include "#{partial_path}.md" %})
            end
          else
            %({% include "#{filename}" %})
          end
        end
      end
    end
  end
end
