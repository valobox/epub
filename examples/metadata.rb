require './lib/example'

Example.setup("metadata") do |epub|
  puts "title=%s" % epub.metadata[:title]
  puts "Setting title to 'Office Badgers'"
  epub.metadata[:title] = "Office Badgers"
  puts "title=%s" % epub.metadata[:title]
end