module Epub
  class ZipFile
    include Logger

    def initialize(filepath)
      @filepath = filepath
    end


    def self.unzip(zip_filepath, dirpath)
      Zip::ZipFile.open(zip_filepath) do |zf|
        zf.each do |e| 
          fpath = ::File.join(dirpath, e.name)
          FileUtils.mkdir_p ::File.dirname(fpath)

          log "unziping #{e.name} to #{fpath}"
          begin
            zf.extract(e, fpath)
          rescue => e
            # NOTE: We just log the error here as we may not need this file
            # Any errors will occur when we try to read the file later on
            log "WARN: #{e.message}"
          end
        end
      end
    end


    def self.zip(dirpath, zip_filepath)
      zip_filepath_bak = "#{zip_filepath}_bak"
      # Backup the old file
      FileUtils.cp(zip_filepath, zip_filepath_bak)

      begin
        # Create the new zip
        # NOTE: This overides the zip file
        Zip::ZipFile::open(zip_filepath, true) do |zf|
          Dir["#{dirpath}/**/*"].each do |f|
            pn_f       = Pathname.new(f)
            pn_dirpath = Pathname.new(dirpath)
            rel_path   = pn_f.relative_path_from(pn_dirpath)

            log "#{f} to #{rel_path}"
            zf.add(rel_path, f){true} # true proc overwrites files
          end
        end

        # Remove the backup
        FileUtils.rm(zip_filepath_bak)
      rescue
        FileUtils.mv(zip_filepath_bak, zip_filepath)
        raise "Failed to create zip"
      end
    end


    # Open a file in the Epub
    #
    # @param [String] filepath in the Epub
    # @yield [Zip::ZipFileSystem::ZipFsFile] file system zip file
    def open(filepath)
      zip_open do |zip|
        zip.file.open(filepath, "r") do |file|
          yield(file)
        end
      end
    end


    # Make a directory in the epub
    #
    # @param [String] path of the new directory
    def mkdir(path)
      zip_open do |zip|
        begin
          zip.mkdir(path)
        rescue
        end
      end
      nil
    end


    # Write data to a filepath
    #
    # @param [String] filepath
    # @param [String] data to write to the file
    def write(filepath, data=nil)
      zip_open do |zip|
        zip.get_output_stream(filepath) do |file|
          if block_given?
            yield(file)
          else
            file.puts data
          end
        end
      end
      nil
    end


    # Removes a file from the epub
    #
    # @param [String] filepath
    def rm(filepath)
      zip_open do |zip|
        zip.remove(filepath)
      end
    end


    # Moves files in the Epub
    #
    # @param [String] current filepath
    # @param [String] new filepath
    def mv(current_filepath, new_filepath)
      log "mv #{current_filepath} #{new_filepath}"
      data = read(current_filepath)

      rm(current_filepath)
      write(new_filepath, data)
      nil
    end


    # Iterates over each file in the Epub
    #
    # @param [Symbol] type of entry to return, can be `:file` or `:directory`. 
    #                 A nil value will return both
    def each(type=nil)
      Zip::ZipFile.foreach(@filepath) do |entry|
        file_type = entry.file? ? :file : :directory

        case type
        when :file
          yield(entry) if file_type == :file
        when :directory
          yield(entry) if file_type == :directory
        else
          yield(entry)
        end
      end
      nil
    end


    # Removes any empty directorys in the epub
    def clean_empty_dirs!
      Zip::ZipFile.foreach(@filepath) do |entry|
        if entry.directory?
          zip_open do |zip|
            is_empty = false
            zip.dir.open(entry.to_s) do |d|
              is_empty = true if d.entries.size < 1
            end

            if is_empty
              zip.remove(entry.to_s)
            end
          end
        end
      end
      nil
    end


    # 
    # Read a file from the epub
    #
    # @param [String] filepath to a file in the epub zip
    # @return [Nokogiri::XML]
    def read(filepath)
      data = nil
      open(filepath) do |file|
        data = file.read.clone
      end
      data
    end


    # Read an xml file from the epub and parses with Nokogiri
    #
    # @param [String] filepath to an xml document in the epub zip
    # @return [Nokogiri::XML]
    def read_xml(filepath)
      data = read(filepath)
      Nokogiri::XML data
    end


    # Extract a epub file to a location on the file system.
    #
    # @param [String] filepath to an Epub
    # @param [String] extract_filepath of a directory to extract to
    def extract(filepath, extract_filepath)
      zip_open do |zip|
        # Make sure the dir exists
        FileUtils.mkdir_p ::File.dirname(extract_dir)

        fname = ::File.basename(filepath)
        fpath = ::File.join(extract_dir, fname)

        raise "File already exists" if ::File.exists?(fpath)

        # Extract!
        zip.extract(filepath, fpath)
      end
      nil
    end


    private

      # Opens the zip file
      #
      # @yield [Zip::ZipFile] zip file
      def zip_open
        Zip::ZipFile.open(@filepath, true) do |zip|
          yield(zip)
        end
      end

  end
end