module Epub

  class SassLine
    include PathManipulation

    attr_accessor :src

    def initialize(epub, item, line, directive_indent = nil)
      @epub = epub
      @item = item
      @line = line.chomp!
      @directive_indent = directive_indent
    end

    def indent
      @line.sub(/^(\s*).*$/, "\\1").size
    end

    def is_css_directive?
      @line.to_s =~ /^\s*@/
    end

    def inside_css_directive?
      @directive_indent && indent > @directive_indent
    end

    def has_path?
      @line =~ /url\(.*\)/
    end

    def normalize_paths
      # Split it up into its parts
      #            |   $1     |$2|    $3     |$4|
      #                url     ("   path.jpg  ")
      @line.gsub!(/(url)\s*(\(["']?)(.+?)(["']?\))/) do |url|

        # set the image source
        self.src = $3

        # Check its not an external url
        if !is_external_link? && !blank_link?

          # If a linked item is found
          if linked_item
            new_src  = linked_item.normalized_hashed_path(relative_to: @item.normalized_hashed_path)
            new_url  = "#{$1}#{$2}#{new_src}#{$4}"

            @epub.log "Changing #{url} to #{new_url}"

            # override the original string
            url.replace new_url
          else
            @epub.log "Failed to find file #{self.src} referenced in #{@item.filepath}"
          end
        end
      end
    end

    def src
      @src || ""
    end

    def to_s
      @line
    end

    def linked_item
      @item.get_item(clean_src)
    end

    def missing_item?
      !is_external_link? && !blank_link? && !linked_item
    end

    private

      def clean_src
        strip_anchors src.gsub(" ", "%20")
      end

      def is_external_link?
        external_link?(clean_src)
      end

      def blank_link?
        clean_src.to_s == ""
      end

  end
end