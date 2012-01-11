require './lib/example'

Example.setup("manifest") do |epub|
  epub.manifest.items.each do |item|
    puts item.filepath
  end
end