require 'html_compressor'

module Epub
  class HTML < Item
    include Logger

    STYLESHEET_XPATH = "//link[@rel='stylesheet']"

    def initialize(filepath, epub) 
      super(filepath, epub)

      @type        = :html
      @normalized_dir = "OEBPS"

      # Force to .xhtml in normalize process
      @file_ext_overide = ".xhtml"
    end


    # Normalizes the html by flattening the file paths, also:
    #  * Removes scripts
    #  * Standardizes the DOM structure
    # 
    # @see Epub::File#normalize!
    def normalize!
      data = read
      html = Nokogiri::XML.parse(data)
      html.encoding = 'utf-8'

      # Process the @DOM
      standardize_dom(html)
      remove_scripts(html)
      change_hrefs(html)

      write(html.to_s)
    end

    def compress!
      data = read
      data = HtmlCompressor::HtmlCompressor.new.compress(data)

      write(data)
    end


    private


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
      def standardize_dom(html)
        if !html.css("body")
          html.css(":not(head)").wrap("<body></body>")
        end

        if !html.css("html")
          html.wrap("<html></html>")
        end
        nil
      end


      # Removes all script tags
      #
      # @param [Nokogiri::XML] html document DOM
      def remove_scripts(html)
        html.css('script').each do |node|
          node.remove
        end
        nil
      end


      # Rewrites all hrefs to their normalized form
      #
      # @param [Nokogiri::XML] html document DOM
      def change_hrefs(html)
        DOM.walk(html) do |node|
          for attr_name in %w{href src}
            attr_obj = node.attributes[attr_name]

            # Ignore if its blank
            next if !attr_obj

            # URL encode any spaces
            orig_href = attr_obj.to_s.gsub(" ", "%20")

            begin
              src = URI(orig_href)
            rescue
              log "#{orig_href} not a valid URI"
              next
            end

            if internal_link?(src.to_s)
              linked_item = nil

              if src.path == ""
                # If its just an anchor like '#this' just set to the current file
                linked_item = self
              else
                # Match on the unescaped href
                unescaped_path = URI::unescape(src.path)
                linked_item = get_item(unescaped_path)
              end

              # Change link
              if linked_item
                new_path = linked_item.normalized_hashed_path(:relative_to => self)
                new_path = URI(new_path)

                if src.fragment
                  new_path.fragment = src.fragment
                end

                log "Changing #{src.to_s} to #{new_path.to_s}"
                attr_obj.content = new_path.to_s
              else
                log "No item in manifest for #{src}"
              end
            end
          end
        end
      end

      def internal_link?(href)
        # Catch all hrefs begining with a protocol 'http:', 'ftp:', 'mailto:'
        if !href || href=="" || href =~ /^[a-zA-Z]+?:/
          return false
        end

        return true
      end
  end
end