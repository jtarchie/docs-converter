#!/usr/bin/env ruby
# frozen_string_literal: true

require 'capybara'
require 'capybara/dsl'
require 'nokogiri'
require 'selenium-webdriver'

Capybara.run_server = false
Capybara.default_driver = :selenium_chrome_headless

include Capybara::DSL

logger = Logger.new(STDOUT)

base_url = ARGV[0]

raise 'Please provide a URL to check anchor tags' if base_url.nil?

sites = [base_url]
found_links = {}
found_anchors = {}

until sites.empty?
  site = sites.pop
  next if found_links.key?(site)

  logger.info "visiting #{site}"
  visit site

  logger.info 'parsing links'
  absolute_links = page.all('a[href]').map { |a| a['href'] }
  found_links[site] = absolute_links.select do |uri|
    uri.include?(base_url)
  end

  logger.info 'parsing anchors'
  found_anchors[site] = Nokogiri::HTML(page.html).css('*[id]').map do |a|
    a['id']
  end
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

found_links.values.flatten.uniq.each do |link|
  next unless link.include?('#')
  next if sitewide_anchors.include?(link)

  logger.warn "#{link} goes nowhere"
end
