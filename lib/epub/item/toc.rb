module Epub
  class Toc < Item
    include XML

    ROOT_XPATH  = '//xmlns:navMap'
    ITEMS_XPATH = '//xmlns:navMap/xmlns:navPoint'
    CHILD_XPATH = 'xmlns:navPoint'

    ITEM_TEXT_XPATH = 'xmlns:navLabel/xmlns:text'
    ITEM_FILE_XPATH = 'xmlns:content'


    def initialize(filepath, epub)
      super(filepath, epub)

      @type = :toc
      @normalized_dir = "OEBPS"
    end


    def as_hash(opts={})
      items xmldoc.xpath(ITEMS_XPATH), opts
    end


    # Normalizes the toc by flattening the file paths
    # 
    # @see Epub::File#normalize!
    def normalize!
      doc = xmldoc
      nodes doc.xpath(ITEMS_XPATH) do |node|
        content_node = node.xpath(ITEM_FILE_XPATH).first
        src = content_node.attributes['src'].to_s

        src = URI(src)
        item = get_item(src.to_s)

        filepath = URI(item.normalized_hashed_path(:relative_to => self))
        if src.fragment
          filepath.fragment = src.fragment
        end

        content_node['src'] = filepath.to_s
      end


      root = read_xml

      # Replace the node, bit messy
      node = root.xpath(ROOT_XPATH).first
      doc_partial = Nokogiri::XML(doc.to_s)
      node.replace(doc_partial.root)

      # Write it back
      data = root.to_s
      write(data)
    end


    private

      def xmldoc
        read_xml.xpath(ROOT_XPATH)
      end

      def items(master, opts={}, level=0)
        items = []

        master.each do |node|
          label = xpath_content(node, ITEM_TEXT_XPATH)
          src   = xpath_attr(node, ITEM_FILE_XPATH, 'src')
          src   = URI(src)

          child = node.xpath(CHILD_XPATH)
          child_nodes = {}
          if child
            # Recurse
            child_nodes = items(child, opts, level+1)
          end

          # Get the references epub item
          file = get_item(src.to_s)

          # Position for sorting
          position = 0
          play_order = node.attributes['playOrder']
          
          # FIX: Why-oh-why does `to_s -> to_i` work and not just to_i??
          position = play_order.to_s.to_i if play_order

          # Get the filepath
          filepath = nil
          if opts[:normalize]
            filepath = file.normalized_hashed_path(:relative_to => self)
          else
            filepath = file.filepath
          end

          raise "Error" if !filepath

          filepath = URI(filepath)

          # Add back in the anchor
          if src.fragment
            filepath.fragment = src.fragment
          end

          # Build the Hash fragment
          if file && label
            items << {
              :label    => label.strip,
              :url      => filepath.to_s,
              :children => child_nodes,
              :position => position
            }
          end
        end

        # Sort children based on their position
        items.sort! do |x,y|
          x[:position] <=> y[:position]
        end
        return items
      end


      def nodes(master)
        master.each do |node|
          yield(node)

          child = node.xpath(CHILD_XPATH)
          if child
            nodes(child) do |node|
              yield(node)
            end
          end
        end
      end
  end
end