require './lib/example'

Example.setup("spine") do |epub|
  pp epub.toc.as_hash
end