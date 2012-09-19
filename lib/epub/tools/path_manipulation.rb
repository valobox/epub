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
      CGI.unescape(href.strip).gsub(" ", "+")
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

    # get the path to one file from another
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

    # escape a filepath so spaces and non standard characters in the filename are escaped
    def escape_path(path)
      filename = ::File.basename(path)
      folder   = ::File.dirname(path)

      # avoid turning style.css into ./style.css
      if folder == "."
        filename
      else
        ::File.join folder, CGI.escape(unescape_path(filename))
      end
    end

    # turn an escaped path into a usable path
    def unescape_path(path)
      CGI.unescape(path.to_s)
    end

  end
end