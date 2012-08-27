module Epub
  class HtmlLink
    include Logger

    attr_accessor :item, :node, :href

    def initialize(item, node, href)
      @item = item
      @node = node
      @href = href
    end

    def normalize
      if !external_link?
        if linked_item
          log "Changing #{src.to_s} to #{new_src.to_s}"
          href.content = new_src.to_s
        else
          log "No item in manifest for #{src.to_s}"
        end
      end
    end


    private

      def clean_href
        href.to_s.gsub(" ", "%20")
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
      def external_link?
        clean_href =~ /^[a-zA-Z]+?:/# || href == ""
      end

  end
end