module Epub
  # An item inside the <Epub::Manifest>
  class Item < Base

    include PathManipulation

    # @attr_reader [Symbol] type of item (gets overidden in subclasses)
    attr_reader :type, :id

    # Initialize with a manifest id
    #
    #     Item.new(epub, "cover-image")
    #
    def initialize(epub, id)
      @epub = epub
      @id   = id
      @type = :misc
      @normalized_dir = "OEBPS/assets"

    end


    ###
    # File data accessors
    ###

    # TODO: Should this be here???
    def read_xml
      @epub.file.read_xml(abs_filepath)
    end

    # TODO: Should be overidden by image to read binary data
    def read
      @epub.file.read(abs_filepath)
    end

    def write(data)
      @epub.file.write(abs_filepath) do |file|
        file << data
      end
    end

    # Extract file to the _path_ specified
    # @param [String] path
    def extract(path)
      @epub.file.extract(abs_filepath, path)
    end


    # Boolean of if the file this item represents exists
    def exists?
      ::File.exists?(abs_filepath)
    end


    ###
    # Paths
    ###


    # Returns the filename of the item
    def filename
      ::File.basename(filepath)
    end

    def filename_without_ext
      ext = ::File.extname(filepath)
      ::File.basename(filepath, ext)
    end


    # Path relative to the Epubs opf file
    def filepath
      escape_path @epub.manifest.path_from_id(@id)
    end


    # Path absolute to the Epubs base directory, this will be different
    # depending on the Epub type @see Epub::File.type
    # * *zip:* Root of the zip filesystem
    # * *directory:* Root relative to base epub directory
    def abs_filepath
      @epub.manifest.abs_path_from_id(@id)
    end


    # Get an item based on the path from this item
    # TODO: Might need to escape URL
    def get_item(path_to_file)
      # Remove anchors
      path_to_file = strip_anchors(path_to_file)

      abs_path_to_file = abs_path_to_file(path_to_file)

      item = @epub.manifest.item_for_path( abs_path_to_file )

      if !item
        raise "Failed to find item in manifest for #{path_to_file}"
      end

      item
    end


    # returns the full path to an item after it is hashed
    # /html/chapters/1.html #=> /html/a42901.html
    # @options
    # - :relative_to #=> a path to build the path relative to
    # Uses
    # - use to move an item to it's normalized location
    # - use to generate a url to an asset relative to another for changing hrefs
    def normalized_hashed_path(options = {})
      relative_path(abs_normalized_hashed_path, options[:relative_to])
    end


    # Flattens the epub structure, _overidden by subclasses_
    # @see Epub::File#normalize!
    def normalize!; end

    # Compress item data, _overidden by subclasses_
    def compress!; end

    def create_manifest_entry(href)
      abs_filepath = abs_path_to_file(href)
      @epub.manifest.add(abs_filepath)
    end

    def log(str)
      @epub.log(str)
    end


    private

      # create an absolute path to a file #=> 'OEBPS/HTML/' + '../CSS/style.css' = 'OEBPS/CSS/style.css' 
      def abs_path_to_file(path_to_file)
        clean_path(base_dirname, path_to_file)
      end

      def base_dirname
        Pathname.new(filepath).dirname.to_s
      end

      # The hashed filename
      # /html/chapters/1.html #=> a42901.html
      def hashed_filename
        "#{hash(abs_filepath)}-#{filename_without_ext}#{file_ext}"
      end

      def file_ext
        @file_ext_overide || ::File.extname(abs_filepath)
      end

      def abs_normalized_hashed_path
        ::File.join(@normalized_dir, hashed_filename)
      end

  end
end