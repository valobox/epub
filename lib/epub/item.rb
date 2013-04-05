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
      super
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
      @epub.file.write(abs_filepath, data)
    end


    # Extract file to the _path_ specified
    # @param [String] path
    def extract(path)
      @epub.file.extract(abs_filepath, path)
    end


    # Boolean of if the file this item represents exists
    def exists?
      File.exists?(abs_filepath)
    end


    # Saves the item back to the epub
    def save
      write(to_s)
    end


    ###
    # Paths
    ###

    # Returns the filename of the item
    def filename
      unescape_path File.basename(filepath)
    end


    def filename_without_ext
      ext = File.extname(filepath)
      File.basename(filepath, ext)
    end


    # Path relative to the Epubs opf file
    def filepath
      unescape_path url
    end


    # Path absolute to the Epubs base directory, this will be different
    # depending on the Epub type @see Epub::Document.type
    # * *zip:* Root of the zip filesystem
    # * *directory:* Root relative to base epub directory
    def abs_filepath
      unescape_path abs_url
    end


    def url
      escape_url @epub.manifest.path_from_id(@id)
    end


    def abs_url
      escape_url @epub.manifest.abs_path_from_id(@id)
    end


    # Get an item based on the path from this item
    # TODO: Might need to escape URL
    def get_item(path_to_file)

      # unescape the path so the filesystem can find it
      path_to_file = unescape_path(path_to_file)

      # Remove anchors in case it's a url
      path_to_file = strip_anchors(path_to_file)

      # Get the absolute path to the file from the epub item
      abs_path_to_file = abs_path_to_file(path_to_file)

      if item_in_manifest = @epub.manifest.item_for_path( abs_path_to_file )
        item_in_manifest
      else
        @epub.manifest.add( abs_path_to_file )
      end
    end


    # returns the full path to an item after it is hashed
    # /html/chapters/1.html #=> /html/a42901.html
    # @options
    # - :relative_to #=> a path to build the path relative to
    # Uses
    # - use to move an item to it's normalized location
    # - use to generate a url to an asset relative to another for changing hrefs
    def normalized_hashed_path(options = {})
      unescape_path normalized_hashed_url options
    end


    def normalized_hashed_url(options = {})
      escape_url relative_path(abs_normalized_hashed_path, options[:relative_to])
    end


    # Standardizes the contents of the item, _overidden by subclasses_
    def standardize!; end


    # Flattens the epub structure, _overidden by subclasses_
    # @see Epub::Document#normalize!
    def normalize!; end


    # Compress item data, _overidden by subclasses_
    def compress!; end


    def create_manifest_entry(href)
      @epub.manifest.add( abs_path_to_file(href) )
    end


    def log(*args)
      @epub.log(args)
    end


    # create an absolute path to a file #=> 'OEBPS/HTML/file.html' + '../CSS/style.css' = 'OEBPS/CSS/style.css' 
    def abs_path_to_file(path_to_file)
      clean_path(base_dirname, path_to_file)
    end

    private

      def base_dirname
        Pathname.new(filepath).dirname.to_s
      end


      # The hashed filename
      # /html/chapters/1.html #=> a42901-1.html
      def hashed_filename
        "#{hash_path(abs_filepath)}-#{filename_without_ext}#{file_ext}"
      end


      def file_ext
        @file_ext_overide || File.extname(abs_filepath)
      end


      def abs_normalized_hashed_path
        File.join(@normalized_dir, hashed_filename)
      end

  end
end