require 'date'

module Epub
  # An item inside the <Epub::Manifest>
  class Item

    # @attr_reader [Symbol] type of item (gets overidden in subclasses)
    attr_reader :type

    # Initialize with a manifest id
    #
    #     Item.new(epub, {
    #       :id => "cover-image"  # From the content.opf
    #     })
    #
    def initialize(epub, opts)
      @epub = epub
      @type = :misc
      @normalized_dir = "OEBPS/assets"

      @id = opts.delete(:id)

      raise "File #{opts} not valid" if !@id
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
        file.puts(data)
      end
    end

    # Extract file to the _path_ specified
    # @param [String] path
    def extract(path)
      @epub.file.extract(abs_filepath, path)
    end


    ###
    # Paths
    ###

    # Path relative to the Epubs opf file
    def filepath
      @epub.manifest.path_from_id(@id)
    end

    def filename(opts={})
      path = @epub.manifest.path_from_id(@id)
      if opts[:no_ext]
        ext = ::File.extname(path)
        ::File.basename(path, ext)
      else
        ::File.basename(path)
      end
    end

    # Path absolute to the Epubs base directory, this will be different
    # depending on the Epub type @see Epub::File.type
    # * *zip:* Root of the zip filesystem
    # * *directory:* Root relative to base epub directory
    def abs_filepath
      @epub.manifest.abs_path_from_id(@id)
    end


    # TODO: Might need to escape URL
    # TODO: Need to normalize the path here
    def get_item(rel_path)      
      # Remove anchors
      rel_path.sub!(/#.*$/, "")

      base = ::File.dirname(filepath)
      path = ::File.join(base, rel_path)
      path = Pathname.new(path).cleanpath.to_s

      item = @epub.manifest.item_for_path(path.to_s)

      if !item
        raise "Failed to find item in manifest for #{rel_path}"
      end

      item
    end


    def normalized_hashed_path(opts={})
      path = ::File.join(@normalized_dir, hashed_filename)

      if opts[:relative_to]
        rel_item = opts[:relative_to]

        base = nil
        if rel_item.is_a?(Item)
          base = rel_item.normalized_hashed_path
        else
          base = rel_item
        end

        base = Pathname.new(base)
        path = Pathname.new(path)

        path = path.relative_path_from(base.dirname)
        path = path.to_s
      end

      path
    end

    # Hash of the absolute filepath
    def hash
      Digest::MD5.hexdigest(abs_filepath)[0..5]
    end


    # Flattens the epub structure, _overidden by subclasses_
    # @see Epub::File#normalize!
    def normalize!; end

    # Compress item data, _overidden by subclasses_
    def compress!; end


    private

      # The hashed filename
      def hashed_filename
        ext = ::File.extname(abs_filepath)
        ext = @file_ext_overide if @file_ext_overide

        # Add the extension to the hashed filename
        filename = "%s%s" % [hash, ext]
        filename
      end

  end
end