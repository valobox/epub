module Epub

  # Represents a line of the toc xml
  # <navPoint id="navpoint-3" playOrder="3"><navLabel><text>Title page</text></navLabel><content src="html/003_tp.html#tp"/></navPoint>
  class TocElement
    include XML
    include PathManipulation


    def initialize(toc, node)
      @toc = toc
      @node = node
    end


    # Build an array set of TocElements
    def self.build(toc, master_node)
      master_node.collect do |node|
        toc_element = self.new(toc, node)

        # Recurse through the toc_element children
        if toc_element.child_node
          toc_element.child_elements = self.build(toc, toc_element.child_node)
        end

        toc_element
      end
    end


    # Build an array of hash representations of TocElements
    def self.as_hash(elements)
      out = []

      elements.each do |element|
        element_hash = element.to_hash
        if element.child_elements
          element_hash[:children] = self.as_hash(element.child_elements)
        end
        out << element_hash
      end

      # Sort children based on their position
      out.sort! do |x,y|
        x[:position] <=> y[:position]
      end
    end

    ##############
    # Accessors
    ##############

    attr_accessor :child_elements

    def label
      xpath_content(@node, item_text_xpath)
    end

    def src
      URI xpath_attr(@node, item_file_xpath, 'src')
    end

    def child_node
      @node.xpath(child_xpath)
    end

    def play_order
      if @node.attributes['playOrder']
        @node.attributes['playOrder'].to_s.to_i
      else
        0
      end
    end

    ##############
    # Item attributes
    ##############

    def standardize_url!
      content_node = @node.xpath(item_file_xpath).first
      content_node['src'] = escape_url(content_node['src'])
    end

    def normalize_url!(options = {})
      content_node = @node.xpath(item_file_xpath).first # FIXME: duplicate of src?
      content_node['src'] = normalize_url(options).to_s
    end

    def to_hash
      {
        label:    label.strip,
        url:      url.to_s,
        position: play_order,
        children: []
      }
    end

    private

      def child_xpath
        'xmlns:navPoint'
      end

      def item_text_xpath
        'xmlns:navLabel/xmlns:text'
      end

      def item_file_xpath
        'xmlns:content'
      end

      # TODO - look at decoupling item
      def item
        @toc.get_item(src.to_s)
      end

      # TODO - look at decoupling item
      # Add the anchor to the url
      def url
        escape_url(item.url)
      end

      # Create a normalized url of an item
      # TODO - look at decoupling item
      def normalize_url(options = {})
        escape_url(item.normalized_hashed_url(options))
      end
  end
end