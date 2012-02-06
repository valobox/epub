module Epub
  class Guide
    # @private
    OPF_XPATH = '//xmlns:guide'

    # @private
    OPF_ITEM_XPATH = '//xmlns:reference'

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

      @epub.save_opf!(doc, OPF_XPATH)
    end

    def to_s
      xmldoc.to_s
    end


    private

      def xmldoc
        @epub.opf_xml.xpath(OPF_XPATH)
      end

      # Iterate over each item in the guide
      def items
        xmldoc.xpath(OPF_ITEM_XPATH).each do |item|
          yield(item)
        end
      end

  end
end