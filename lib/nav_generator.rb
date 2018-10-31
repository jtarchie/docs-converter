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
      return [] unless root

      links(root.css('> li').to_a)
    end

    private

    def links(nodes)
      nav = []
      while li = nodes.shift
        nav += [parse_li(li, nodes)]
      end
      nav
    end

    def parse_li(li, nodes)
      if link = li.css('> a[href]').first
        name = link.text
        uri = link['href'].gsub('.html', '.md').to_s
        if ul = li.css('> ul').first
          { name => [{ 'Home' => uri }] + links(ul.css('> li').to_a) }
        else
          { name => uri }
        end
      elsif span = li.css('> span').first
        name = span.text
        ul = li.css('> ul').first
        { name => links(ul.css('> li').to_a) }
      elsif strong = li.css('> strong').first
        name = strong.text

        links = []
        while sibling = nodes.shift
          if sibling['class'].to_s.include?('has_submenu')
            nodes.unshift sibling
            break
          end

          links.push(parse_li(sibling, sibling.css('> li').to_a))
        end
        { name => links }
      end
    end
  end
end
