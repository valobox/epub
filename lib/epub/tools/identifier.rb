module Epub
  class Identifier

    attr_accessor :epub, :id, :media_type, :href, :klass

    def initialize(epub, node)
      @epub       = epub
      @id         = node.attributes['id'].to_s
      @media_type = node.attributes['media-type'].to_s
      @href       = node.attributes['href'].to_s
      @klass      = set_klass
    end

    def item
      klass.new(epub, {:id => id})
    end

    private

      def set_klass
        if is_toc?
          Toc
        elsif class_from_mimetype
          class_from_mimetype
        elsif class_from_path
          class_from_path
        else
          Item
        end
      end

      def is_toc?
        epub.spine.toc_manifest_id == id
      end

      def class_from_mimetype
        case media_type
        when 'text/css'
          CSS
        when /^image\/.*$/
          Image
        when /^application\/xhtml.*$/
          HTML
        else
          nil
        end
      end
        

      def class_from_path
        klass = case path
        when /\.(css)$/
          CSS
        when /\.(png|jpeg|jpg|gif|svg)$/
          Image
        when /\.(html|xhtml)$/
          HTML
        else
          nil
        end
      end
  end
end