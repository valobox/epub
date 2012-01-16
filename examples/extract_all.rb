$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'epub'
require 'fileutils'


orig_filepath = "epubs/example.epub"
temp_filepath = "epubs/_extract_all.example.epub"

FileUtils.cp orig_filepath, temp_filepath

Epub::File.extract(temp_filepath) do |epub, path|
  puts "temp extracted filepath '#{path}'"
  epub.manifest.items.each do |item|
    total_path = File.join(path, item.abs_filepath)
    puts "abs_filepath=#{total_path}"
    puts "Writing '<h1>Hello</h1>' to #{item}"
    item.write("<h1>Hello</h1>")
  end
end

puts "Output EPUB: #{temp_filepath}"