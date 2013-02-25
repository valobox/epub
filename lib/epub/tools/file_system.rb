require 'fileutils'

module Epub
  class FileSystem

    def initialize(basepath)
      @basepath = basepath
    end


    def open(filepath)
      path = abs_filepath(filepath)
      ::File.open(path, "r") do |file|
        yield(file)
      end
    end


    def mkdir(path)
      path = abs_filepath(path)
      FileUtils.mkdir_p(path)
    end


    def write(filepath, data = nil, &block)
      path = abs_filepath(filepath)

      ::File.open(path, "w+") do |file|
        if block_given?
          yield(file)
        else
          file.write data.to_s
        end
      end
    end


    def ammend(filepath, data, &block)
      path = abs_filepath(filepath)
      ::File.write(path, "#{read(filepath)}\n#{data}")
    end


    def rm(filepath)
      path = abs_filepath(filepath)
      FileUtils.rm(path)
    end


    def mv(existing_path, new_path)
      existing_path = abs_filepath(existing_path)
      new_path = abs_filepath(new_path)

      if existing_path == new_path
        # Do nothing the files are the same
        return
      end

      # Make sure the target path exists
      dirname = ::File.dirname(new_path)
      FileUtils.mkdir_p(dirname) if !::File.exists?(dirname)

      # log "mv #{existing_path} to #{new_path}"
      FileUtils.mv(existing_path, new_path)
      nil
    end


    def each(force_type=nil)
      Dir["#{@basepath}/**/*"].each do |entry|
        type = ::File.file?(entry) ? :file : :directory

        case force_type
        when :file
          yield(entry) if type == :file
        when :directory
          yield(entry) if type == :directory
        else
          yield(entry)
        end
      end
    end


    # TODO: Add omit option here
    def clean_empty_dirs!
      Dir["#{@basepath}/**/*"].each do |f|
        if ::File.directory?(f) && Dir.entries(f).size < 3 # 3 because of ['.', '..']
          # log "Removing empty directory #{f}"
          FileUtils.rmdir(f)
        end
      end
    end


    # Read a file from the epub
    def read(path)
      path = abs_filepath(path)
      ::File.read(path)
    end


    # Read an xml file from the epub and parses with Nokogiri
    def read_xml(filepath)
      data = read(filepath)
      Nokogiri::XML data
    end


    # Extract a epub file to a location on the file system
    #   * filepath    - epub filepath
    #   * extract_dir - directory to extract to
    def extract(filepath, extract_dir)
      if ::File.file?(extract_dir)
        raise "Output directory is a file"
      elsif ::File.directory?(extract_dir)
        # Do nothing
      else
        FileUtils.mkdir(extract_dir)
      end

      fname = ::File.basename(filepath)
      fpath = ::File.join(extract_dir, fname)

      raise "File already exists" if ::File.exists?(fpath)

      FileUtils.cp abs_filepath(filepath), fpath
      fpath
    end


    def exists?(filepath)
      ::File.exists?(abs_filepath(filepath))
    end


    private

      def abs_filepath(filepath)
        ::File.join(@basepath, filepath)
      end
  end
end