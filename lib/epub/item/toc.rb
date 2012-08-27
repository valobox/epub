module Epub
  class Toc < Item
    include XML


    def initialize(filepath, epub)
      super(filepath, epub)

      @type = :toc
      @normalized_dir = "OEBPS"
    end


    # Create an array of hash representations of the TOC
    def as_hash
      TocElement.as_hash TocElement.build(self, navmap_elements)
    end


    # loop through list of navmap items
    # Replace the src with the normalized src
    def normalize
      nodes(navmap_elements) do |node|
        TocElement.new(self, node).normalize_filepath!(relative_to: self.normalized_hashed_path)
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

    def to_s
      as_hash.to_yaml
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


      def nodes(master)
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