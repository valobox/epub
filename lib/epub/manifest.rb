require 'digest/md5'
require 'pathname'

module Epub
  class Manifest
    # @private
    OPF_XPATH       = '//xmlns:manifest'

    # @private
    OPF_ITEMS_XPATH = '//xmlns:item'

    # @private
    OPF_ITEM_XPATH  = '//xmlns:item[@id="%s"]'

    # @private
    XML_NS = {
      'xmlns' => 'http://www.idpf.org/2007/opf'
    }

    def initialize(epub)
      @epub = epub
      reload_xmldoc
    end

    def reload_xmldoc
      @xmldoc = @epub.opf_xml.xpath(OPF_XPATH, 'xmlns' => XML_NS['xmlns'])
    end
    

    # Normalizes the manifest by flattening the file paths
    # 
    # @see Epub::File#normalize!
    def normalize!
      # Flatten epub items
      items(:image, :html, :css, :misc) do |item,node|
        item.normalize!
      end

      # Flatten manifest
      items do |item,node|
        # Move the file to flattened location
        @epub.file.mv item.abs_filepath, item.normalized_hashed_path

        # Renames based on asbsolute path from base
        node['href'] = item.normalized_hashed_path(:relative_to => "OEBPS/content.opf")
      end

      @epub.save_opf!(@xmldoc, OPF_XPATH)
      @epub.file.mv @epub.opf_path, "OEBPS/content.opf"

      # Move the opf file
      opf_path = "OEBPS/content.opf"
      @epub.opf_path = opf_path

      # Reset the XMLDOC
      reload_xmldoc
    end



    # Pretty display
    def to_s
      @xmldoc.to_s
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
    # @param [Array] filter can any of [:css, :html, :image, :misc] a nil value
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
    def [](key)
      item_for_path path_from_id(key)
    end


    # TODO:
    # mimetype - should be optional
    def add(id, path, mimetype)
      item_klass = item_class_from_mimetype(mimetype) || item_class_from_path(path)

      item = Nokogiri::XML::Node.new "item", @xmldoc.first
      item['id']         = id
      item['href']       = path
      item['media-type'] = mimetype
      @xmldoc.first.add_child(item)

      puts "item_klass=#{item_klass}"

      @epub.save_opf!(@xmldoc, OPF_XPATH)
    end


    def path_from_id(key)
      xpath = OPF_ITEM_XPATH % key
      nodes = @xmldoc.xpath(xpath)

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


    def abs_path_from_id(key)
      rel  = path_from_id(key)
      base = ::File.dirname(@epub.opf_path)
      path = ::File.join(base, rel)
      Pathname.new(path).cleanpath.to_s
    end


    def rel_path(path)
      base = Pathname.new(@epub.opf_path)
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

      return nil if !node

      id         = node.attributes['id'].to_s
      media_type = node.attributes['media-type'].to_s
      href       = node.attributes['href'].to_s

      klass = nil

      # Is it the TOC
      if @epub.spine.toc_manifest_id == id
        klass = Toc
      end

      # Get type based on media-type
      if !klass && media_type
        klass = item_class_from_mimetype(media_type)
      end

      # Get type based on file extension
      if !klass
        klass = item_class_from_path(href)
      end

      klass = Item if !klass

      item = klass.new(@epub, {
        :id => id
      })

      item
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

      def nodes
        @xmldoc.xpath(OPF_ITEMS_XPATH).each do |node|
          yield(node)
        end
      end


      def node_for_path(path)
        nodes do |node|
          if CGI::unescape(node.attributes['href'].to_s) == CGI::unescape(path)
            return node
          end
        end
        nil
      end


      def item_class_from_mimetype(mimetype)
        return case mimetype
        when 'text/css'
          CSS
        when /^image\/.*$/
          Image
        when /^application\/xhtml.*$/
          HTML
        else
          nil
        end
      end
      

      def item_class_from_path(path)
        case path
        when /\.(css)$/
          CSS
        when /\.(png|jpeg|jpg|gif|svg)$/
          Image
        when /\.(html|xhtml)$/
          HTML
        else
          nil
        end
      end
  end
end