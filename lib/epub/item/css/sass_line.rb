module Epub

  class SassLine

    def initialize(item, line, directive_indent = nil)
      @item = item
      @line = line.chomp!
      @directive_indent = directive_indent
    end

    def indent
      @line.sub(/^(\s+).*$/, "\\1").size
    end

    def is_css_directive?
      @line =~ /^\s+@/
    end

    def inside_css_directive?
      @directive_indent && indent > @directive_indent
    end

    def has_path?
      @line =~ /url\(.*\)/
    end

    def rewrite_paths
      # Split it up into its parts
      @line.gsub!(/(url\(["']?)(.+?)(["']?\))/) do |m|
        # Array for the new rule
        new_rule = [$1, nil, $3]
        src = $2

        # Check its not an external url
        if src !~ /^http[s]?:\/\// && src && src != ''
          # Delete any anchors (just incase)
          src = src.sub(/^(.*)\#$/, "$1")

          # Build the filename
          src_item = @item.get_item(src)
          new_rule[1] = src_item.normalized_hashed_path(relative_to: self)

          # override the original string
          m.replace new_rule.join
        end
      end
    end

    def to_s
      @line
    end

  end
end