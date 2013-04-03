module Epub
  module PathManipulation

    private

    ###############
    # URL helpers
    ###############

    def add_anchor_to_url(url, fragment = nil)
      if fragment
        "#{url}##{fragment}"
      else
        url
      end
    end

    # A rough fix so URI(path) will work
    # Should use escape_url in most cases
    def clean_url(href)
      # TODO: A better way would be to split by / then take the last section, strip off the anchor then cgi escape
      URI.unescape(href.strip).gsub(" ", "%20")
    end

    def strip_anchors(path)
      path.sub(/#.*$/, "")
    end

    def get_anchor(url)
      url = clean_url(url)
      URI(url).fragment
    end

    def external_link?(path)
      path =~ /^[a-zA-Z]+?:/
    end

    # escape the url ensuring the anchor is kept
    def escape_url(url)
      add_anchor_to_url escape_path(url), get_anchor(url)
    end


    ##############
    # Path helpers
    ##############

    # Returns a clean path based on input paths
    # /OEPS/html/../CSS/style.css #=> /OEPS/CSS/style.css
    # @args
    # - list of paths to join and clean
    def clean_path(*args)
      path = File.join(args.to_a.compact)
      Pathname.new(path).cleanpath.to_s
    end

    # escape a filepath so spaces and non standard characters in the filename are escaped
    def escape_path(path)
      # Strip anchors incase input is in a url form (as per guide)
      path = strip_anchors(path)
      filename = File.basename(path)
      folder   = File.dirname(path)
      # avoid turning style.css into ./style.css
      if folder == "."
        URI.escape(unescape_path(filename))
      else
        File.join folder, URI.escape(unescape_path(filename))
      end
    end

    # turn an escaped path into a usable path
    def unescape_path(path)
      URI.unescape(path.to_s)
    end

    ##############
    # General helpers
    ##############

    # Hash of the absolute filepath
    def hash_path(path)
      Digest::MD5.hexdigest(path)[0..5]
    end

    # get the path to one file from another
    def relative_path(path_to, path_from)
      path_from ||= ""
      path_to  = Pathname.new(path_to)
      dir_from = Pathname.new(path_from).dirname

      path_to.relative_path_from(dir_from).to_s
    end

  end
end