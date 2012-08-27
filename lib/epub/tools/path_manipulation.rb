module Epub
  module PathManipulation

    private

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

  end
end