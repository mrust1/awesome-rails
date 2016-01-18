require 'parallel'
require 'nokogiri'
require 'open-uri'
require 'httparty'
require 'kramdown'

def check_link(uri)
  code = HTTParty.head(uri, :follow_redirects => false).code
  return code >= 200 && code < 400
end

BASE_URI = ENV['BASE_URI'] || "https://github.com/dpaluy/awesome-rails"

doc = Nokogiri::HTML(Kramdown::Document.new(open('README.md').read).to_html)
links = doc.css('a').to_a
puts "Validating #{links.count} links..."

invalids = []
Parallel.each(links, :in_threads => 4) do |link|
  begin
    uri = URI.join(BASE_URI, link.attr('href'))
    check_link(uri)
    putc('.')
  rescue
    putc('F')
    invalids << "#{link} (reason: #{$!})"
  end
end

unless invalids.empty?
  puts "\n\nFailed links:"
  invalids.each do |link|
    puts "- #{link}"
  end
  puts "Done with errors."
  exit(1)
end

puts "\nDone."
