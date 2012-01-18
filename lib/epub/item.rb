require 'date'

module Epub
  class Item
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

    def filepath
      @epub.manifest.path_from_id(@id)
    end

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

      @epub.manifest.item_for_path(path.to_s)
    end


    def hashed_filepath
      hashed_filepath(filepath)
    end
    

    def abs_hashed_filepath
      hashed_filepath(abs_filepath)
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


    ###
    # Read file data
    ###
    def read_xml
      @epub.file.read_xml(abs_filepath)
    end


    def read
      @epub.file.read(abs_filepath)
    end

    def write(data)
      @epub.file.write(abs_filepath) do |file|
        file.puts(data)
      end
    end

    def extract(extract_path)
      @epub.file.extract(abs_filepath, extract_path)
    end


    ###
    # Overidden methods
    ###
    def normalize!
      # Just a placeholder
    end

    def compress!
      # Just a placeholder
    end

    

    private

      # The hashed filename
      def hashed_filename
        ext = ::File.extname(abs_filepath)

        # Add the extension to the hashed filename
        filename = "%s%s" % [hash, ext]
        filename
      end

  end
end