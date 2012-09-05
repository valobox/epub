module Epub
  class Metadata < Base
    include XML

    attr_accessor :epub


    def initialize(epub)
      @epub = epub
    end


    # Setter
    def []=(key, value)
      doc = xmldoc
      obj = xml_def[key]

      # Error if not a valid metadata entry
      raise "#{key} not valid" if !obj
      
      xpath = "//#{obj[:node]}"
      node = doc.xpath(xpath, 'dc' => xml_ns['dc']).first

      if node
        # Node exists so set it
        node.content = value
      else
        # Node doesn't exist create it
        node = Nokogiri::XML::Node.new "dc:title", doc
        node.content = value
        doc.add_child(node)
      end

      epub.save_opf!(doc, opf_xpath)
    end


    # Getter
    def [](key)
      obj = xml_def[key]

      # Get the content
      xpath = "//#{obj[:node]}"
      v = xmldoc.xpath(xpath, 'dc' => xml_ns['dc']).first
      v = v.content.to_s if v

      # Run throught the processor if there are any
      v = self.send(obj[:processor], v) if obj[:processor]
      v
    end


    # 
    def to_s
      out = []
      xml_def.each do |k,v|
        val = self[k]
        out << "#{k}: #{val}"
      end
      out.join "\n"
    end


    private

      def opf_xpath
        '//xmlns:metadata'
      end

      def xml_ns
        {
          'xmlns' => 'http://www.idpf.org/2007/opf',
          'dc'    => "http://purl.org/dc/elements/1.1/"
        }
      end

      def xml_def
        {
          :title => {
            :node => "dc:title"
          },
          :isbn => {
            :node => "dc:identifier",
            :processor => :isbn
          },
          :language => {
            :node => "dc:language"
          },
          :creator => {
            :node => "dc:creator"
          },
          :publisher => {
            :node => "dc:publisher"
          },
          :description => {
            :node => "dc:description",
            :processor => :sanitize
          },
          :date => {
            :node => "dc:date",
            :processor => :date
          }
        }
      end


      def xmldoc
        epub.opf_xml.xpath(opf_xpath, 'xmlns' => xml_ns['xmlns']).first
      end

      ###
      # Processor methods
      ###

      # Matches the format urn:isbn:9780735664852
      def isbn(text)
        match = text.match(/^\s*urn:isbn:([0-9]{13,13})\s*$/)
        if match
          return match[1]
        end

        match = text.match(/^\s*([0-9]{13,13})\s*$/)
        if match
          return match[1]
        end

        nil
      end

      def date(str)
        date_arr = str.split("-") if str.length

        return nil if date_arr.length != 3

        Date.new(
          date_arr[0].to_i,
          date_arr[1].to_i,
          date_arr[2].to_i
        )
      rescue
        nil
      end

      def sanitize(str)
        if str
          # Convert \u2014
          str = str.gsub(/\\u(\d{2,4})/) {
            # Convert to decimal
            decimal = Integer("0x"+$1)
            # return HTML entity
            "&##{decimal};"
          }

          str = Sanitize.clean(str)
          str = str.strip
        else
          ""
        end
      end
  end
end