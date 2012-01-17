require './lib/example'

Example.setup("normalize") do |epub, filepath|
  epub.normalize!

  # FILE SYSTEM
  Epub::File.extract(filepath) do |epub, path|
    epub.normalize!
  end
end