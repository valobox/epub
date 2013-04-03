module Epub
  class HtmlLink
    include PathManipulation

    attr_accessor :item, :href, :old_href

    def initialize(item, href)
      @item = item
      @href = href
      @old_href = href.to_s
    end


    def normalize
      # TODO: need to handle anchor only links. At the moment they are left as they are.
      # For ease of processing later it might be best to re-label them to the full path to the existing file
      if !is_external_link? && !blank_link? && !anchor_link?
        if linked_item
          log "Changing href #{src.to_s} to #{new_src.to_s}"
          href.content = new_src.to_s
        else
          log "No item in manifest for #{src.to_s}", :error
        end
      end
    end


    def missing_item?
      !is_external_link? && !blank_link? && !anchor_link? && !linked_item
    end


    def log(*args)
      item.log(args)
    end

    private

      def src
        clean_url(old_href).to_s
      end


      def src_fragment
        URI.parse(src).fragment
      end


      def linked_item
        item.get_item(src)
      end


      def linked_item_normalized_path
        linked_item.normalized_hashed_path(relative_to: item.normalized_hashed_path)
      end


      def new_src
        base = clean_url(linked_item_normalized_path)
        add_anchor_to_url(base, src_fragment)
      end


      # Catch all hrefs begining with a protocol 'http:', 'ftp:', 'mailto:'
      def is_external_link?
        external_link?(src)
      end


      def blank_link?
        src.strip == ""
      end


      def anchor_link?
        src.match(/^\#.*/) != nil
      end

  end
end