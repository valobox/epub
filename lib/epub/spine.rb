module Epub
  class Spine
    OPF_XPATH      = '//xmlns:spine'
    OPF_ITEM_XPATH = '//xmlns:itemref'

    def initialize(epub)
      @epub = epub
    end


    def items
      manifest = @epub.manifest
      items = []

      nodes do |node|
        id = node.attributes['idref']
        items << manifest[id] if id
      end

      items
    end


    def toc
      @epub.manifest[toc_manifest_id]
    end


    def to_s
      xmldoc.to_s
    end

    def toc_manifest_id
      toc_manifest_id = xmldoc.attributes['toc']
      toc_manifest_id.to_s.strip
    end


    # <itemref idref="itemid"/>
    def add(item)
      node = Nokogiri::XML::Node.new "itemref", xmldoc
      node['idref'] = "test"

      doc = xmldoc
      doc.add_child(node)
      @epub.save_opf!(doc, OPF_XPATH)
    end


    private


      def xmldoc
        @epub.opf_xml.xpath(OPF_XPATH).first
      end

      def nodes
        xmldoc.xpath(OPF_ITEM_XPATH).each do |node|
          yield(node)
        end
      end

  end
end