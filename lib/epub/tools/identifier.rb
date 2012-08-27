module Epub
  class Identifier

    attr_accessor :epub, :node, :klass, :id, :href, :media_type

    def initialize(epub, node = nil, options = {})
      @epub       = epub
      @node       = node
      @options    = options

      if node
        @id         = node.attributes['id'].to_s
        @href       = node.attributes['href'].to_s
        @media_type = node.attributes['media-type'].to_s
      elsif options
        @id         = options[:id]
        @href       = options[:href]
        @media_type = options[:media_type]
      end

      @klass      = set_klass
    end

    def item
      klass.new(epub, id) if valid?
    end

    def valid?
      id && klass
    end

    def mimetype_from_path
      return unless href
      mimetype = case href
      when /\.(css)$/
        "text/css"
      when /\.gif$/
        "image/gif"
      when /\.png$/
        "image/jpeg"
      when /\.(jpeg|jpg)$/
        "image/jpeg"
      when /\.(html|xhtml)$/
        "application/xhtml+xml"
      else
        nil
      end
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
        return unless id
        epub.spine.toc_manifest_id == id
      end

      def class_from_mimetype
        return unless media_type
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
        return unless href
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