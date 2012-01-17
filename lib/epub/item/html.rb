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


      def add_base_stylesheet(html)
        # TODO: Add the base css here instead
        @epub.manifest.css.each do |css|
          # Add <link rel="stylesheet" href="css/book.css" type="text/css">
          css_link = Nokogiri::XML::Node.new "link", html
          css_link['rel']  = "stylesheet"
          css_link['href'] = css.normalized_hashed_path(:relative_to => self)
          css_link['type'] = "text/css"

          html.css("head").children.last.add_next_sibling(css_link)
        end
      end

      # Indent by stylesheet and remove all linked stylesheets
      # TODO: This should also extract inline <style></style>
      def indent_by_stylesheet_class(html)
        stylesheets = html.xpath(STYLESHEET_XPATH)
        if stylesheets.size

          css_classes = []
          css_str = stylesheets.each do |l|
            href = l[:href]
            href = Pathname.new(href).cleanpath.to_s

            # Get the epub item
            item = get_item(href)

            raise "Missing item" if !item

            css_classes << "#{STYLESHEET_PREFIX}-#{item.hash}"
          end

          css_class_str = css_classes.join(" ")

          body = html.search('body').first
          body_class = body.attributes['class']
          body['class'] = "#{body_class} #{css_class_str}"
        end
      end

      def remove_scripts(html)
        html.xpath('//script').each do |node|
          node.remove
        end
      end

      def change_hrefs(html)
        html.xpath('//a | //img').each do |node|
          attr_name = case node.name
          when 'a'
            'href'
          when 'img'
            'src'
          end

          src = URI(node.attributes[attr_name].to_s)

          if internal_link?(src.to_s)
            # Change internal links
            item = get_item(src.to_s)
            if item
              new_path = item.normalized_hashed_path(:relative_to => self)
              new_path = URI(new_path)

              if src.fragment
                new_path.fragment = src.fragment
              end

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