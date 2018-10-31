module Docs
  class NavGenerator
    def initialize(path:)
      @path = path
    end

    def to_hash
      return [] unless @path

      site_links = Nokogiri::HTML(File.read(@path)).css('ul li a')
      site_links.map do |link|
        name = link.text
        uri  = File.basename(link['href']).gsub('.html', '.md').to_s
        { name => uri }
      end
    end
  end
end