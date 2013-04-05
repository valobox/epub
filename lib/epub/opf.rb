module Epub
  class Opf

  	attr_accessor :xmldoc, :epub

  	def initialize(epub, *args)
  		@epub = epub
  	end

  	def save
      epub.save_opf!(xmldoc, opf_xpath)
      get_xmldoc
  	end


    def get_xmldoc
      @xmldoc = epub.opf_xml.xpath(opf_xpath, 'xmlns' => 'http://www.idpf.org/2007/opf')
    end

    def opf_xpath
    	'/'
    end

  end
end