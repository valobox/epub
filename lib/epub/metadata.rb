require 'date'

module Epub
  class Metadata
    include XML

    OPF_XPATH = '//xmlns:metadata'

    XML_NS = {
      'xmlns' => 'http://www.idpf.org/2007/opf',
      'dc'    => "http://purl.org/dc/elements/1.1/"
    }

    # Property list
    XMLDEF = {
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


    def initialize(rootdoc, epub)
      @rootdoc = rootdoc
      @xmldoc  = rootdoc.xpath(OPF_XPATH, 'xmlns' => XML_NS['xmlns'])
      @epub    = epub
    end


    # Setter
    def []=(k,v)
      obj = XMLDEF[k]

      # Error if not a valid metadata entry
      raise "#{k} not valid" if !obj
      
      xpath = "//#{obj[:node]}"
      node = @xmldoc.xpath(xpath, 'dc' => XML_NS['dc']).first

      if node
        # Node exists so set it
        node.content = v
      else
        # Node doesn't exist create it
        node = Nokogiri::XML::Node.new k.to_s, @rootdoc
        node.content = v
        @xmldoc.children.last.add_previous_sibling(node)
      end

      @epub.save_opf!(@xmldoc, OPF_XPATH)
    end


    # Getter
    def [](key)
      obj = XMLDEF[key]

      # Get the content
      xpath = "//#{obj[:node]}"
      v = @xmldoc.xpath(xpath, 'dc' => XML_NS['dc']).first
      v = v.content.to_s if v

      # Run throught the processor if there are any
      v = self.send(obj[:processor], v) if obj[:processor]
      v
    end


    # 
    def to_s
      out = []
      XMLDEF.each do |k,v|
        val=self[k]
        out << "#{k}: #{val}"
      end
      out.join "\n"
    end


    private

      ###
      # Processor  methods
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
        Sanitize.clean(str)
      end
  end
end