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
      elements do |element|
        element.standardize_url!
      end
    end

    # standardizes and saves the toc to the epub
    def standardize!
      standardize
      save
    end


    # loop through list of navmap items
    # Replace the src with the normalized src
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


    # Write the xml back to file
    def save
      write(xmldoc)
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

    def to_s
      as_hash
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
        '//xmlns:navMap/xmlns:navPoint'
      end

      def child_xpath
        'xmlns:navPoint'
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