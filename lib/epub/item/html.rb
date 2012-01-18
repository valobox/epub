require 'html_compressor'

module Epub
  class HTML < Item
    include Logger

    STYLESHEET_XPATH = "//link[@rel='stylesheet']"

    def initialize(filepath, epub) 
      super(filepath, epub)

      @type        = :html
      @normalized_dir = "OEBPS"
    end

    def normalize!
      data = read
      html = Nokogiri::HTML.parse(data)
      html.encoding = 'utf-8'

      # Normalize!
      normalize(html)

      # Remove the uneeded bits
      remove_scripts(html)
      remove_inline_stylesheets(html)
      remove_linked_stylesheets(html)

      # Flatten the urls
      change_hrefs(html)

      # Stylesheets
      #add_base_stylesheet(html)
      #indent_by_stylesheet_class(html) 

      write(html.to_s)
    end

    def compress!
      data = read
      data = HtmlCompressor::HtmlCompressor.new.compress(data)

      write(data)
    end


    private


      # Make sure it's in a normalized structure
      #
      #    <html>
      #      <head>
      #        <!-- stylesheets here -->
      #      </head>
      #      <body>
      #        <!-- dom elements here -->
      #      </body>
      #    </html>
      def normalize(html)
        if !html.css("body")
          html.wrap("<body></body>")
        end

        if !html.css("html")
          html.search(":not(head)").wrap("<html></html>")
        end 
      end


      def remove_linked_stylesheets(html)
        # TODO: This should add it to the master stylesheet and indent appropriately
        html.search(STYLESHEET_XPATH).remove
      end


      def remove_inline_stylesheets(html)
        # TODO: This should add it to the master stylesheet and indent appropriately
        html.search('style').remove
      end


      def remove_scripts(html)
        html.css('script').each do |node|
          node.remove
        end
      end

      def change_hrefs(html)
        html.css('a, img').each do |node|

          attr_name = case node.name
          when 'a'
            'href'
          when 'img'
            'src'
          when 'link'
            'href'
          end

          orig_href = node.attributes[attr_name].to_s

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
              linked_item = self
            end

            # Change link
            if linked_item
              new_path = linked_item.normalized_hashed_path(:relative_to => self)
              new_path = URI(new_path)

              if src.fragment
                new_path.fragment = src.fragment
              end

              log "Changing #{src.to_s} to #{new_path.to_s}"
              node[attr_name] = new_path.to_s
            else
              log "No item in manifest for #{src}"
            end
          end
        end
      end

      def internal_link?(href)
        if !href || href=="" || href =~ /^http[s]?:\/\// || href =~ /^mailto:/
          return false
        end

        return true
      end
  end
end