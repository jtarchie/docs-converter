#!/usr/bin/env ruby
# frozen_string_literal: true

require 'capybara'
require 'capybara/dsl'
require 'nokogiri'
require 'selenium-webdriver'

Capybara.register_driver :selenium_chrome_headless do |app|
  Capybara::Selenium::Driver.load_selenium
  browser_options = ::Selenium::WebDriver::Chrome::Options.new
  browser_options.args << '--headless'
  browser_options.args << '--no-sandbox'
  browser_options.args << '--disable-gpu' if Gem.win_platform?
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options)
end

Capybara.run_server = false
Capybara.default_driver = :selenium_chrome_headless

include Capybara::DSL

logger = Logger.new(STDOUT)

base_url = ARGV[0]

raise 'Please provide a URL to check anchor tags' if base_url.nil?

base_url = URI.parse(base_url).to_s

sites = [base_url]
found_links = {}
found_anchors = {}

until sites.empty?
  site = sites.pop
  next if found_links.key?(site)

  logger.info "visiting #{site}"
  visit site

  logger.info 'parsing links'
  absolute_links = page.all('a[href]')
                       .map { |a| a['href'] }
                       .map { |url| URI.parse(url).to_s }
  found_links[site] = absolute_links.select do |uri|
    uri.include?(base_url)
  end
  logger.info "found #{found_links[site].size} links"

  logger.info 'parsing anchors'
  found_anchors[site] = Nokogiri::HTML(page.html).css('*[id]').map do |a|
    a['id']
  end
  logger.info "found #{found_anchors[site].size} anchors"
  sites += found_links[site].map do |link|
    uri = URI.parse(link)
    "#{uri.scheme}://#{uri.host}:#{uri.port || '80'}#{uri.path}"
  end
  sites.uniq!
end

sitewide_anchors = found_anchors.map do |site, anchors|
  uri = URI.parse(site)
  anchors.map do |anchor|
    uri.fragment = anchor
    uri.to_s
  end
end.flatten.compact.uniq

logger.info "total unique anchors found: #{sitewide_anchors.size}"

bad_anchors = found_links.values.flatten.uniq.select do |link|
  link.include?('#') && !sitewide_anchors.include?(link)
end

exit 0 if bad_anchors.empty?

bad_anchors.each do |link|
  logger.warn "#{link} goes nowhere"
end
exit 1
