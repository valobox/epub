module Epub
  class Guide
    OPF_XPATH      = '//xmlns:guide'
    OPF_ITEM_XPATH = '//xmlns:reference'

    def initialize(epub)
      @epub   = epub
    end


    # Normalizes the guide by flattening the file paths
    # 
    # @see Epub::File#normalize!
    def normalize!
      doc = xmldoc
      # TODO: Handle this better
      return if doc.size < 1

      items do |node|
        href = CGI::unescape(node.attributes['href'].to_s)
        item = @epub.manifest.item_for_path(href)

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