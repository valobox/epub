require './lib/example'

Example.setup("metadata") do |epub|
  puts "title=%s" % epub.metadata[:title]
  puts "Setting title to 'Office Badgers'"
  epub.metadata[:title] = "Office Badgers"

  puts "description=%s" % epub.metadata[:description]
  puts "title=%s"       % epub.metadata[:title]
end