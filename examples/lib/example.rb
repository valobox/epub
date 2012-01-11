$:.unshift(File.join(File.dirname(__FILE__), '../..', 'lib'))

require 'epub'
require 'fileutils'
require 'pp'

class Example

  def self.setup(name)

    orig_filepath = "epubs/example.epub"
    temp_filepath = "epubs/_#{name}.example.epub"

    FileUtils.cp orig_filepath, temp_filepath

    epub = Epub::File.new(temp_filepath)

    yield(epub)

    puts "Output EPUB: #{temp_filepath}"
  end
  
end