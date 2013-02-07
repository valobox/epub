module Epub

  # Represents a line of the toc xml
  # <navPoint id="navpoint-3" playOrder="3"><navLabel><text>Title page</text></navLabel><content src="html/003_tp.html#tp"/></navPoint>
  class TocElement
    include XML
    include PathManipulation

    attr_accessor :toc, :node, :child_elements

    # create a new TocElement
    # attrs:
    # - toc #=> Epub::Toc
    # - node #=> Nokogiri::XML::Node of a toc.ncx navMap element
    def initialize(toc, node)
      @toc = toc
      @node = node
    end


    # Build a nested set of TocElements with the children populated
    def self.build(toc, master_node)
      master_node.collect do |node|
        toc_element = self.new(toc, node)

        # Recurse through the toc_element children
        if toc_element.child_nodes
          toc_element.child_elements = self.build(toc, toc_element.child_nodes)
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

    def id
      @node['id']
    end

    def id=(id)
      @node['id'] = id.to_s.strip
    end

    def label
      label_node.content
    end

    def label=(label)
      label_node.content = label.strip
    end

    def src
      content_node['src']
    end

    def src=(src)
      content_node['src'] = src
    end

    # present the url escaped src
    def url
      escape_url src
    end

    def play_order
      if @node['playOrder']
        @node['playOrder'].to_s.to_i
      else
        0
      end
    end

    def play_order=(play_order)
      @node['playOrder'] = play_order.to_s
    end

    def path
      URI(url).path
    end

    ##############
    # Item methods
    ##############

    def standardize_url!
      self.src = escape_url(src)
    end

    def normalize_url!(options = {})
      self.src = normalize_url(options).to_s
    end

    def to_hash
      {
        id:       id,
        label:    label,
        url:      url,
        position: play_order,
        children: []
      }
    end

    def child_nodes
      @node.xpath(child_xpath)
    end

    private

      def child_xpath
        # 'xmlns:navPoint'
        'navPoint'
      end

      def item_text_xpath
        # 'xmlns:navLabel/xmlns:text'
        'navLabel/text'
      end

      def item_file_xpath
        # 'xmlns:content'
        'content'
      end

      # TODO - look at decoupling item
      def item
        @item ||= @toc.get_item(path.to_s)
      end

      def content_node
        @node.xpath(item_file_xpath).first
      end

      def label_node
        @node.xpath(item_text_xpath).first
      end

      # Create a normalized url of an item including the anchor
      def normalize_url(options = {})
        href = URI(url)
        href.path = item.normalized_hashed_url(options)
        href.to_s
      end
  end
end