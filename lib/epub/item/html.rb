module Epub
  class HTML < Item

    attr_accessor :html

    def initialize(epub, id) 
      super(epub, id)

      @type        = :html
      @normalized_dir = "OEBPS"

      # Force to .xhtml in normalize process
      @file_ext_overide = ".xhtml"
    end

    def standardize!
      standardize
      save
    end

    def standardize
      log "Standardizing html #{filepath}..."
      standardize_dom
      remove_scripts
      add_css_namespace
      html
    end

    # Normalizes the html by flattening the file paths, also:
    #  * Removes scripts
    #  * Standardizes the DOM structure
    # 
    # @see Epub::File#normalize!
    def normalize!
      normalize
      save
    end

    # Process the @DOM
    def normalize
      log "Normalizing html #{filepath}..."
      normalize_links
    end

    def compress!
      log "compressing html file #{filepath}"
      write( HtmlCompressor::HtmlCompressor.new.compress(read) )
    end

    def to_s
      html
    end

    def html
      @html || doc.to_s
    end

    private

      def doc
        @doc ||= Nokogiri::HTML.parse(read)
        @doc.encoding = 'utf-8'
        @doc
      end

      def stylesheet_xpath
        "//link[@rel='stylesheet']"
      end

      # Makes sure the DOM is in the following normalized structure
      #
      #    <html>
      #      <head>
      #        <!-- stylesheets here -->
      #      </head>
      #      <body>
      #        <!-- dom elements here -->
      #      </body>
      #    </html>
      #
      # @param [Nokogiri::XML] html document DOM
      def standardize_dom
        if !doc.css("body")
          log "adding body tag to #{filepath}"
          doc.css(":not(head)").wrap("<body></body>")
        end

        if !doc.css("html")
          log "adding html tag to #{filepath}"
          doc.wrap("<html></html>")
        end
        nil
      end


      # Removes all script tags
      #
      # @param [Nokogiri::XML] html document DOM
      def remove_scripts
        doc.css('script').each do |node|
          log "removing script #{node.to_s} from #{filepath}"
          node.remove
        end
        nil
      end


      # Rewrites all hrefs to their normalized form
      #
      # @param [Nokogiri::XML] html document DOM
      def normalize_links
        DOM.walk(doc) do |node|
          for attr_name in %w{href src}
            href = node.attributes[attr_name]
            if href
              html_link = HtmlLink.new(self, href)
              # All links should be escaped and normalized
              html_link.normalize
            end
          end
        end
      end


      def add_css_namespace
        body = doc.css("body").first
        body_classes = body['class'].to_s.strip.split(" ")
        body['class'] = (body_classes + stylesheet_filenames).join(" ")
      end


      def stylesheet_filenames
        css_classes = doc.css("link[@type='text/css']").collect do |css_node|
          css = get_item(css_node['href'])
          "epub_#{css.filename_without_ext}"
        end
      end


      # Prefix all ids, classes and names with an underscore
      def prefix_css_selectors(prefix = "_")
        DOM.walk(doc) do |node|
          for attr_key in %w(id name class)
            if attr_val = node.attributes[attr_key]
              node[attr_key] = "#{prefix}#{attr_val.to_s}"
            end
          end
        end
      end
  end
end