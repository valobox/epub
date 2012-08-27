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
      normalize
      save
    end


    # Normalizes and returns the normalized guide contents
    def normalize
      doc = xmldoc

      # TODO: Handle this better
      if doc.size < 1
        return
      end

      normalize_paths
      to_s
    end


    # Saves the contents of the guide to the OPF
    def save
      @epub.save_opf!(xmldoc, opf_xpath)
    end


    # Prints the xml
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

      def base_dirname
        @epub.opf_dirname
      end

      # Iterate over each item in the guide
      def entries
        xmldoc.xpath(opf_item_xpath).each do |entry|
          yield(entry)
        end
      end

      def normalize_paths

        entries do |node|
          href_str = node.attributes['href'].to_s
          href = CGI::unescape(href_str)
          item = @epub.manifest.item_for_path(href)

          if !item
            raise "No item in manifest for #{href_str}"
          end

          node['href'] = item.normalized_hashed_path(relative_to: base_dirname)
        end
        
      end

  end
end