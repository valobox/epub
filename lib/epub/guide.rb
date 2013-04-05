module Epub
  class Guide < Base
    include PathManipulation

    # @param [Epub::Document]
    def initialize(epub)
      super
    end


    def standardize!
      entries do |node|
        node['href'] = escape_url(node['href'])
      end
    end


    # Normalizes the guide by flattening the file paths
    # 
    # @see Epub::Document#normalize!
    def normalize!
      normalize
      save
    end


    # Normalizes and returns the normalized guide contents
    def normalize
      @epub.log "Normalizing guide..."
      doc = xmldoc

      # TODO: Handle this better
      if doc.size < 1
        return
      end

      normalize_paths
      to_s
    end


    # Prints the xml
    def to_s
      xmldoc.to_s
    end

    # Iterate over each item in the guide
    def entries(&block)
      if block_given?
        xmldoc.xpath(opf_item_xpath).each do |entry|
          yield(entry)
        end
      else
        xmldoc.xpath(opf_item_xpath)
      end
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

      def normalize_paths
        entries do |node|
          url = node['href']
          path = escape_path(url)
          item = @epub.manifest.item_for_path(path)

          new_href = item.normalized_hashed_path(relative_to: base_dirname)

          node['href'] = add_anchor_to_url(new_href, get_anchor(url))
        end
        
      end

  end
end