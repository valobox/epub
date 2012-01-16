require './lib/example'

EXTRACT_DIR_ZIP = "epubs/extracted_zip"
EXTRACT_DIR_FS = "epubs/extracted_fs"

Example.setup("extract_file") do |epub, filepath|
  begin
    FileUtils.mkdir EXTRACT_DIR_ZIP
  rescue 
  end

  # ZIP FILE
  puts "Extracted first spine item to #{EXTRACT_DIR_ZIP}"
  epub.spine.items.first.extract(EXTRACT_DIR_ZIP)


  # FILE SYSTEM
  Epub::File.extract(filepath) do |epub, path|
    item = epub.spine.items.first

    puts "Extracted first spine item to #{EXTRACT_DIR_FS}"
    item.extract(EXTRACT_DIR_FS)
  end

end
