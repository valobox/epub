module Epub
  module PathManipulation

    private

    def add_fragment_to_href(href, fragment = nil)
      if fragment
        "#{href}##{fragment}"
      else
        href
      end
    end

    def clean_href(href)
      # TODO: A better way would be to split by / then take the last section, strip off the anchor then cgi escape
      CGI.unescape(href.strip).gsub(" ", "%20")
    end

    # Returns a clean path based on input paths
    # @args
    # - list of paths to join and clean
    def clean_path(*args)
      path = ::File.join(args.to_a.compact)
      Pathname.new(path).cleanpath.to_s
    end

    # Hash of the absolute filepath
    def hash(path)
      Digest::MD5.hexdigest(path)[0..5]
    end

    def relative_path(path_to, path_from)
      path_from ||= ""
      path_to  = Pathname.new(path_to)
      dir_from = Pathname.new(path_from).dirname

      path_to.relative_path_from(dir_from).to_s
    end

    def strip_anchors(path)
      path.sub(/#.*$/, "")
    end

    def external_link?(path)
      path =~ /^[a-zA-Z]+?:/
    end

    def escape_path(path)
      CGI.escape(CGI.unescape(path.to_s))
    end

    def unescape_path(path)
      CGI.unescape(path.to_s)
    end

  end
end