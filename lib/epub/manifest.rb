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

    ###
    # Accessors
    ###
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
    def items(*filter)
      items = []
      nodes do |node|
        href = CGI::unescape(node.attributes['href'].to_s)

        item = item_for_path(href)

        if !item
          raise "No item present for #{href}"
        end

        if filter.size < 1 || filter.include?(item.type)
          if block_given?
            yield(item,node)
          else
            items << item
          end
        end
      end
      items if !block_given?
    end


    # Access item by id, for example `epub.manifest["cover-image"]` will grab the file for
    # the following XML entry
    # 
    #     <item id="cover-image" href="OEBPS/assets/cover.jpg" media-type="image/jpeg"/>
    #
    def [](id)
      item_for_path path_from_id(id)
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


    def path_from_id(id)
      xpath = opf_item_xpath(id)
      nodes = xmldoc.xpath(xpath)

      case nodes.size
      when 0
        return nil
      when 1
        node = nodes.first
        href = CGI::unescape(node.attributes['href'].to_s)
        return Pathname.new(href).cleanpath.to_s
      else
        raise "XPath match more than one entry"
      end
    end


    def abs_path_from_id(id)
      rel  = path_from_id(id)
      base = ::File.dirname(epub.opf_path)
      path = ::File.join(base, rel)
      Pathname.new(path).cleanpath.to_s
    end


    def rel_path(path)
      base = Pathname.new(epub.opf_path)
      path = Pathname.new(path)
      path = path.relative_path_from(base.dirname)
      path.to_s
    end


    def id_for_path(path)
      if node = node_for_path(path)
        return node.attributes['id'].to_s
      else
        nil
      end
    end


    def id_for_abs_path(path)
      id_for_path rel_path(path)
    end


    def item_for_path(path)

      # TODO: Need to get media type here also
      node = node_for_path(path)

      if node
        Identifier.new(epub, node).item
      else
        nil
      end
    end


    def item_for_abs_path(path)
      item_for_path rel_path(path)
    end


    def item(opts)
      path = nil
      if opts[:path]
        path = rel_path(opts[:path])
      elsif opts[:id]
        path = path_from_id(opts[:path])
      else
        raise "Not options given"
      end

      item_for_path(path)
    end



    private

      def opf_path
        "OEBPS/content.opf"
      end

      def opf_xpath
        '//xmlns:manifest'
      end

      def opf_items_xpath
        '//xmlns:item'
      end

      def opf_item_xpath(id)
        '//xmlns:item[@id="%s"]' % id
      end

      def xml_ns
        'http://www.idpf.org/2007/opf'
      end

      def nodes
        xmldoc.xpath(opf_items_xpath).each do |node|
          yield(node)
        end
      end


      def node_for_path(path)
        path = path.split("#").first # sometimes the path contains an anchor name
        nodes do |node|
          if CGI::unescape(node.attributes['href'].to_s) == CGI::unescape(path)
            return node
          end
        end
        nil
      end

      def reload_xmldoc
        xmldoc = get_xmldoc
      end

      def get_xmldoc
        epub.opf_xml.xpath(opf_xpath, 'xmlns' => xml_ns)
      end

      def normalize_item_contents
        items(:image, :html, :css, :misc) do |item,node|
          item.normalize!
        end
      end

      def normalize_item_location
        # Flatten manifest
        items do |item, node|
          # Move the file to flattened location
          epub.file.mv item.abs_filepath, item.normalized_hashed_path

          # Renames based on asbsolute path from base
          node['href'] = item.normalized_hashed_path(:relative_to => opf_path)
        end
      end

      def normalize_opf_path
        epub.save_opf!(xmldoc, opf_xpath)
        epub.file.mv epub.opf_path, opf_path
        epub.opf_path = opf_path
      end
  end
end