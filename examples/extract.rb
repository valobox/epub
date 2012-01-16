$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'epub'
require 'fileutils'


orig_filepath = "epubs/example.epub"
temp_filepath = "epubs/_extract.example.epub"

FileUtils.cp orig_filepath, temp_filepath

Epub::File.extract(temp_filepath) do |epub|
  epub.manifest.items.each do |item|
    puts "Writing '<h1>Hello</h1>' to #{item}"
    puts item.write("<h1>Hello</h1>")
  end
end

puts "Output EPUB: #{temp_filepath}"