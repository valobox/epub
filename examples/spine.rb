require './lib/example'

Example.setup("spine") do |epub|
  epub.spine.items.each do |item|
    puts item.filepath
  end
end