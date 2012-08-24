module Epub
  class Toc < Item
    include XML


    def initialize(filepath, epub)
      super(filepath, epub)

      @type = :toc
      @normalized_dir = "OEBPS"
    end


    def as_hash(opts={})
      items xmldoc.xpath(items_xpath), opts
    end


    # Normalizes the toc by flattening the file paths
    # 
    # @see Epub::File#normalize!
    def normalize!
      doc = xmldoc
      nodes doc.xpath(items_xpath) do |node|
        content_node = node.xpath(item_file_xpath).first
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
      node = root.xpath(root_xpath).first
      doc_partial = Nokogiri::XML(doc.to_s)
      node.replace(doc_partial.root)

      # Write it back
      data = root.to_s
      write(data)
    end


    private

      def root_xpath
        '//xmlns:navMap'
      end

      def items_xpath
        '//xmlns:navMap/xmlns:navPoint'
      end

      def child_xpath
        'xmlns:navPoint'
      end

      def item_text_xpath
        'xmlns:navLabel/xmlns:text'
      end

      def item_file_xpath
        'xmlns:content'
      end

      def xmldoc
        read_xml.xpath(root_xpath)
      end

      def items(master, opts={}, level=0)
        items = []

        master.each do |node|
          label = xpath_content(node, item_text_xpath)
          src   = xpath_attr(node, item_file_xpath, 'src')
          src   = URI(src)

          child = node.xpath(child_xpath)
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

          child = node.xpath(child_xpath)
          if child
            nodes(child) do |node|
              yield(node)
            end
          end
        end
      end
  end
end