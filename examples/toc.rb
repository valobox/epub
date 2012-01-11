require './lib/example'

Example.setup("spine") do |epub|
  puts epub.toc.as_hash
end