# frozen_string_literal: true

require 'nokogiri'

module Docs
  class NavGenerator
    def initialize(path:)
      @path = path
    end

    def to_hash
      return [] unless @path

      root = Nokogiri::HTML(File.read(@path)).css('ul').first
      puts Nokogiri::HTML(File.read(@path)).errors
      return [] unless root

      links(root.css('> li').to_a)
    end

    private

    def links(nodes)
      nav = []
      while li = nodes.shift
        nav += [parse_li(li, nodes)]
      end
      nav.compact
    end

    def parse_li(li, nodes)
      if link = li.css('> a[href]').first
        name = link.text.strip
        uri = link['href'].gsub('.html', '.md').to_s
        if ul = li.css('> ul').first
          { name => [{ 'Home' => uri }] + links(ul.css('> li').to_a).compact }
        else
          { name => uri }
        end
      elsif span = li.css('> span').first
        return unless span.css('> hr').empty?

        name = span.text.strip
        ul = li.css('> ul').first
        { name => links(ul.css('> li').to_a).compact }
      elsif strong = li.css('> strong').first
        name = strong.text.strip

        links = []
        while sibling = nodes.shift
          unless sibling.css('> strong').empty?
            nodes.unshift sibling
            break
          end

          links.push(parse_li(sibling, sibling.css('> li').to_a))
        end
        { name => links.compact }
      end
    end
  end
end
