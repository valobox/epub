module Epub
  class Guide

    # @param [Epub::File]
    def initialize(epub)
      @epub = epub
    end


    # Normalizes the guide by flattening the file paths
    # 
    # @see Epub::File#normalize!
    def normalize!
      doc = xmldoc

      # TODO: Handle this better
      if doc.size < 1
        return
      end

      items do |node|
        href_str = node.attributes['href'].to_s
        href = CGI::unescape(href_str)
        item = @epub.manifest.item_for_path(href)

        if !item
          raise "No item in manifest for #{href_str}"
        end

        node['href'] = item.normalized_hashed_path(:relative_to => @epub.opf_path)
      end

      @epub.save_opf!(doc, Epub::Manifest.opf_xpath)
    end

    def to_s
      xmldoc.to_s
    end


    private

      def opf_xpath
        '//xmlns:guide'
      end

      def opf_item_xpath
        '//xmlns:reference'
      end

      def xmldoc
        @epub.opf_xml.xpath(opf_xpath)
      end

      # Iterate over each item in the guide
      def items
        xmldoc.xpath(opf_item_xpath).each do |item|
          yield(item)
        end
      end

  end
end