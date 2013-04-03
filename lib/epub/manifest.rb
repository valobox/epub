module Epub
  class Manifest < Base
    include PathManipulation

    attr_accessor :epub

    def initialize(epub)
      @epub   = epub
      @xmldoc = get_xmldoc
    end


    def xmldoc
      get_xmldoc
    end


    # Pretty display
    def to_s
      xmldoc.to_s
    end


    ############
    # Processing
    ############
    def standardize!
      log "Standardizing manifest..."
      standardize_hrefs
      standardize_item_contents
    end


    def normalize!
      log "Normalizing manifest..."
      normalize_item_contents
      normalize_item_location
      normalize_opf_contents
      normalize_opf_path
    end

    #########
    # Items
    #########
    def assets
      items :image, :css, :misc
    end


    def images
      items :image
    end


    def html
      items :html
    end


    def css
      items :css
    end


    def misc
      items :misc
    end


    # Retrieve the cover image using the id in the metadata
    def cover_image
      cover_id = epub.metadata.cover_id
      if cover_id
        item_for_id(cover_id)
      else
        false
      end
    end


    # Return items in the manifest file
    #
    # @args filter can any of :css, :html, :image, :misc or a nil value
    #        will return all items
    # @return [Array <Epub::Item>] items
    def items(*filters)
      items = []

      nodes do |node|
        item = item_from_node(node)

        if filters.size == 0 || filters.include?(item.type)
          if block_given?
            yield(item)
          else
            items << item
          end
        end
      end
      items
    end


    # Access item by id, for example `epub.manifest["cover-image"]` will grab the file for
    # the following XML entry
    # 
    #     <item id="cover-image" href="OEBPS/assets/cover.jpg" media-type="image/jpeg"/>
    #
    def [](id)
      item_for_id(id)
    end


    # Add an item to the manifest
    # @args
    # - path #=> Absolute path from epub root to item
    # @returns
    #   Epub::Item if the item was added
    def add(path)
      log "Adding item to manifest for path #{abs_path(path)}"

      puts "path: #{path}"

      item = item_for_path(path)

      puts "item: #{item.inspect}"

      if item
        log "File already in manifest #{abs_path(path)}", :error
        nil

      elsif @epub.file.exists?(abs_path(path))
        log "adding #{abs_path(path)} to the manifest..."
        node = Nokogiri::XML::Node.new "item", xmldoc.first

        id = hash_path(path)
        node['id']         = id
        node['href']       = rel_path(path)
        node['media-type'] = MIME::Types.type_for(path).first

        xmldoc.first.add_child(node)
        epub.save_opf!(xmldoc, opf_xpath)

        item_for_id(id)

      else
        log "File not found #{abs_path(path)}", :error
        nil
      end
    end


    # Find the path to a file relative to the manifest
    # @args
    # - Id #=> the id of the item in the manifest
    def path_from_id(id)
      node = node_from_id(id)
      if node
        clean_path(node.attributes['href'].to_s)
      end
    end


    # Find the absolute path to a file (relative to epub root)
    # @args
    # - Id #=> the id of the item in the manifest
    def abs_path_from_id(id)
      clean_path(dirname, path_from_id(id))
    end


    # Find the Epub::Item based on a path relative to the opf
    # @args
    # - path #=> path to file relative to the OPF root
    def item_for_id(id)
      item_from_node(node_from_id(id))
    end


    # Generate a relative path from the opf file
    # @args
    # - abs_path #=> The absolute path to the file
    def rel_path(abs_path)
      relative_path(abs_path, dirname)
    end


    # Find the Epub::Item based on a path relative to the opf
    # @args
    # - path #=> path to file relative to the OPF root
    def item_for_path(path)
      node = node_from_path(path)

      if node
        item_from_node(node) 
      else
        nil
      end
    end


    # Find the Epub::Item based on an abosolute path
    # @args
    # - path #=> path to file relative to epub root
    def item_for_abs_path(path)
      item_for_path rel_path(path)
    end


    # return the path from the epub root given the path from the OPF
    def abs_path(path_from_opf)
      clean_path(@epub.opf_dirname, path_from_opf)
    end

    private

      def opf_path
        "OEBPS/content.opf"
      end


      def opf_xpath
        '//xmlns:manifest'
      end


      def get_xmldoc
        epub.opf_xml.xpath(opf_xpath, 'xmlns' => 'http://www.idpf.org/2007/opf')
      end


      def opf_items_xpath
        '//xmlns:item'
      end


      def xpath_for_id(id)
        "//xmlns:item[@id=\"#{id}\"]"
      end


      # The directory name of the manifest opf
      def dirname
        epub.opf_dirname
      end


      # Loop through all the manifest nodes yielding a blog each time
      def nodes
        nodes = xmldoc.xpath(opf_items_xpath)
        if block_given?
          nodes.each do |node|
            yield(node)
          end
        end
        
        nodes
      end


      # Return an Epub::Item based on a node
      def item_from_node(node)
        Identifier.new(epub, node).item
      end


      # Find the node based on the id
      # @args
      # - id #=> id in the manifest for the node
      def node_from_id(id)
        xmldoc.xpath( xpath_for_id(id) ).first
      end


      # Get the node for an item in the manifest based on it's href
      # @args
      # - path #=> path of file relative to opf
      # @returns
      # - xml node if present
      # Loop through the nodes rather than use xpath find as need case insensitive matching
      # If we find a way to do case insensitive matching can use nokogiri which might be faster
      def node_from_path(path)
        path = escape_path(path).downcase

        nodes do |node|
          node_path = escape_path(node['href']).downcase
          return node if node_path == path
        end

        nil

        # raise("can't find node for path #{path}")
      end


      # All hrefs in the manifest should be escaped
      def standardize_hrefs
        nodes do |node|
          if node['href']
            node['href'] = escape_path( node['href'] )
          end
        end
      end


      def standardize_item_contents
        items(:image, :html, :css, :misc).each do |item|
          item.standardize!
        end
      end


      def normalize_item_contents
        items(:image, :html, :css, :misc).each do |item|
          item.normalize!
        end
      end


      def normalize_item_location
        nodes do |node|
          item = item_from_node(node)

          # Move the file to flattened location
          log "moving file from #{item.abs_filepath} to #{item.normalized_hashed_path}"
          epub.file.mv(item.abs_filepath, item.normalized_hashed_path) if File.exists?(item.abs_filepath)
        end
      end


      def normalize_opf_path
        epub.file.mv epub.opf_path, opf_path
        epub.opf_path = opf_path
      end


      def normalize_opf_contents
        nodes do |node|
          item = item_from_node(node)
          # Renames based on asbsolute path from base
          node['href'] = item.normalized_hashed_path(relative_to: opf_path)
        end
        epub.save_opf!(xmldoc, opf_xpath)
      end


      def log(*args)
        @epub.log(args)
      end
  end
end