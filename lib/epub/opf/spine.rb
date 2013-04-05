module Epub
  class Spine < Opf

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

      xmldoc.add_child(node)
      save
    end


    private

      def opf_xpath
        '//xmlns:spine'
      end


      def opf_item_xpath
        '//xmlns:itemref'
      end


      def xmldoc
        @epub.opf_xml.xpath(opf_xpath).first
      end


      def nodes
        xmldoc.xpath(opf_item_xpath).each do |node|
          yield(node)
        end
      end

  end
end