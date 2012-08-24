require 'digest/md5'
require 'pathname'

module Epub
  class Manifest

    attr_accessor :xmldoc, :epub

    def initialize(epub)
      @epub   = epub
      @xmldoc = get_xmldoc
    end

    # Pretty display
    def to_s
      xmldoc.to_s
    end

    ############
    # Normalize
    ############
    def normalize!
      normalize_item_contents
      normalize_item_location
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
    # - id #=> ID attribute
    # - path #=> href to the file
    # - mimetype #=> Mimetype of the file
    # @returns
    #   Boolean if the item was added
    def add(id, path, mimetype)
      item = Nokogiri::XML::Node.new "item", xmldoc.first
      item['id']         = id
      item['href']       = path
      item['media-type'] = mimetype
      xmldoc.first.add_child(item)

      epub.save_opf!(xmldoc, opf_xpath)
    end


    # Find the path to a file relative to the manifest
    # @args
    # - Id #=> the id of the item in the manifest
    def path_from_id(id)
      node = node_from_id(id)
      if node
        clean_path(CGI::unescape(node.attributes['href'].to_s))
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
      Pathname.new(abs_path).relative_path_from(dirname).to_s
    end


    # Find the Epub::Item based on a path relative to the opf
    # @args
    # - path #=> path to file relative to the OPF root
    def item_for_path(path)
      item_from_node(node_from_path(path))
    end


    # Find the Epub::Item based on an abosolute path
    # @args
    # - path #=> path to file relative to epub root
    def item_for_abs_path(path)
      item_for_path rel_path(path)
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

      def xpath_from_id(id)
        '//xmlns:item[@id="%s"]' % id
      end

      def xpath_from_href(href)
        '//xmlns:item[@href="%s"]' % CGI::unescape(href)
      end


      # Returns a clean path based on input paths
      # @args
      # - list of paths to join and clean
      def clean_path(*args)
        path = ::File.join(args)
        Pathname.new(path).cleanpath.to_s
      end


      # Loop through all the manifest nodes yielding a blog each time
      def nodes
        nodes = xpath_find(opf_items_xpath)
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
        matching_nodes = xpath_find( xpath_from_id(id) )
        first_node(matching_nodes)
      end


      # Get the node for an item in the manifest based on it's href
      # @args
      # - path #=> path of file relative to opf
      # @returns
      # - xml node if present
      # - nil if missing
      def node_from_path(path)
        path = path.split("#").first # sometimes the path contains an anchor name
        matching_nodes = xpath_find( xpath_from_href(path) )
        first_node(matching_nodes)
      end


      # Return the first node from a set or raises an error if more than one are found
      def first_node(nodes)
        if nodes.length > 1
          raise "XPath matched #{nodes.length} entries"
        else
          nodes.first
        end
      end

      def xpath_find(xpath)
        xmldoc.xpath(xpath)
      end

      def normalize_item_contents
        items(:image, :html, :css, :misc) do |item|
          item.normalize!
        end
      end

      def normalize_item_location
        nodes do |node|
          item = item_from_node(node)
          
          # Move the file to flattened location
          epub.file.mv item.abs_filepath, item.normalized_hashed_path

          # Renames based on asbsolute path from base
          node['href'] = item.normalized_hashed_path(relative_to: opf_path)
        end
      end

      def normalize_opf_path
        epub.save_opf!(xmldoc, opf_xpath)
        epub.file.mv epub.opf_path, opf_path
        epub.opf_path = opf_path
      end

      def dirname
        epub.opf_dirname
      end
  end
end