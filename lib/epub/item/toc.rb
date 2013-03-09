module Epub
  class Toc < Item
    include XML


    def initialize(epub, id) 
      super(epub, id)

      @type = :toc
      @normalized_dir = "OEBPS"
    end


    # Create an array of hash representations of the TOC
    def as_hash
      TocElement.as_hash elements
    end

    # replaces all the urls with escaped urls
    def standardize
      log "standardizing NCX XML"
      #
      # WARNING - DIRTY HACK removes namespaces because we get double namespaced ncx:ncx files
      #         - Should detect the double namespace and use different xpaths
      #
      self.write xmldoc.remove_namespaces!

      log "standardizing NCX urls"
      elements do |element|
        element.standardize_url!
      end
    end

    # standardizes and saves the toc to the epub
    def standardize!
      standardize
      save
    end


    # Replace each src attribute with the normalized src URL
    def normalize
      log "Normalizing table of contents..."

      elements do |element|
        element.normalize_url!(relative_to: self.normalized_hashed_path)
      end
      xmldoc
    end


    # Normalizes the toc by flattening the file paths
    # 
    # @see Epub::File#normalize!
    def normalize!
      normalize
      save
    end


    # write out the xmldoc
    def to_s
      xmldoc
    end


    # Output the xml
    def xml
      xmldoc.to_s
    end

    def elements(elements = nil, &block)
      elements ||= TocElement.build(self, navmap_elements)
      if block_given?
        elements.each do |element|
          yield element
          elements(element.child_elements, &block)
        end
      end
      elements
    end


    private

      def xmldoc
        @xmldoc ||= read_xml
      end

      # Read the navmap items
      def navmap_elements
        xmldoc.xpath(items_xpath)
      end

      def items_xpath
        # '//xmlns:navMap/xmlns:navPoint'
        '//navMap/navPoint'
      end

      def child_xpath
        # 'xmlns:navPoint'
        'navPoint'
      end 

      # recurse over the navmap nodes yielding one at a time
      def nodes(master = navmap_elements)
        master.each do |node|
          yield(node)

          child = node.xpath(child_xpath)
          if child
            nodes(child) do |node|
              yield(node)
            end
          end
        end
      end
  end
end