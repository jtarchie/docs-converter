# frozen_string_literal: true

require 'nokogiri'

module Docs
  class NavGenerator
    def initialize(path:)
      @path = path
    end

    def to_hash
      return [] unless @path

      links(Nokogiri::HTML(File.read(@path)).css('ul').first)
    end

    private

    def links(node)
      return [] unless node

      node.css('> li').map do |li|
        next unless link = li.css('a[href]').first

        name = link.text
        uri  = link['href'].gsub('.html', '.md').to_s
        if ul = li.css('ul').first
          { name => [{ 'Home' => uri }] + links(ul) }
        else
          { name => uri }
        end
      end
    end
  end
end
