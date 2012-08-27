module Epub
  class HtmlLink
    include Logger
    include PathManipulation

    attr_accessor :item, :href, :old_href

    def initialize(item, href)
      @item = item
      @href = href
      @old_href = href.to_s
    end

    def normalize
      if !is_external_link? && !blank_link?
        if linked_item
          log "Changing #{src.to_s} to #{new_src.to_s}"
          href.content = new_src.to_s
        else
          log "No item in manifest for #{src.to_s}"
        end
      end
    end


    def missing_item?
      !is_external_link? && !blank_link? && !linked_item
    end


    private

      def clean_href
        old_href.gsub(" ", "%20")
      end

      def src
        begin
          URI(clean_href)
        rescue
          log "#{orig_href} not a valid URI"
        end
      end

      def src_fragment
        src.fragment
      end

      def unescaped_path
        URI::unescape(src.path)
      end

      def linked_item
        item.get_item(unescaped_path)
      end

      def linked_item_normalized_path
        linked_item.normalized_hashed_path(relative_to: item.normalized_hashed_path)
      end

      def new_src
        new_src = URI(linked_item_normalized_path)
        new_src.fragment = src.fragment
        new_src
      end

      # Catch all hrefs begining with a protocol 'http:', 'ftp:', 'mailto:'
      def is_external_link?
        external_link?(clean_href)
      end

      def blank_link?
        unescaped_path.to_s == ""
      end

  end
end