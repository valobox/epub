module Epub

  class SassLine
    include Logger
    include PathManipulation

    attr_accessor :src, :old_src

    def initialize(item, line, directive_indent = nil)
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
      @line.gsub!(/(url\(["']?)(.+?)(["']?\))/) do |url|
        src = $2
        old_src = src.to_s

        # Check its not an external url
        if !is_external_link? && !blank_link?

          # Build the filename
          if linked_item
            new_src  = linked_item.normalized_hashed_path(relative_to: @item.normalized_hashed_path)

            log "Changing #{src.to_s} to #{new_src.to_s}"

            # override the original string
            url.replace "#{$1}#{new_src}#{$3}"
          else
            log "No item in manifest for #{src.to_s}"
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