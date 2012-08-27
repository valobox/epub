module Epub
  class Identifier

    attr_accessor :epub, :node, :klass

    def initialize(epub, node = nil)
      @epub       = epub
      @node       = node
      @klass      = set_klass
    end

    def item
      klass.new(epub, id: id) if node
    end

    private

      def id
        node.attributes['id'].to_s
      end

      def media_type
        node.attributes['media-type'].to_s
      end

      def href
        node.attributes['href'].to_s
      end

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
        klass = case href
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