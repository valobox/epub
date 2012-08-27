require "yui/compressor"
require "sass"
require 'tempfile'

module Epub
  class CSS < Item

    def initialize(filepath, epub)  
      super(filepath, epub)

      @type = :css
      @normalized_dir = "OEBPS"
    end


    # TODO: Split this up into multiple methods
    # Normalizes the guide by flattening the file paths
    # 
    # @see Epub::File#normalize!
    def normalize!
      # Create the sass from css
      sass = css_to_sass(read)

      # remove the @char style css directives (can't be indented)
      sass = remove_css_directives(sass)

      # any refs need rewriting to the normalized paths
      sass = update_paths(sass)

      # fonts need resizing to an em value to enable scaling
      sass = convert_fonts(sass)

      # Parse SASS
      engine = Sass::Engine.new(sass)

      # Render CSS and add it to the string
      css = engine.render

      # Write it to the css file
      write(css)
    end


    def compress!
      compressor = YUI::CssCompressor.new
      data = compressor.compress(read)
      write(data)
    end


    private

      # TODO: Work out how to do this without shelling out
      def css_to_sass(css_data)
        sass = nil
        Tempfile.open("css_to_sass") do |file|
          # Write the css
          file.write css_data

          # Rewind back to the start
          file.rewind

          # Use the std sass command line to convert a CSS file to SASS
          command = "sass-convert #{file.path}"
          sass = `#{command}`
        end
        sass
      end


      # Convert a css size rule value to ems, the supported formats are:
      # * point (24pt)
      # * pixels (24px)
      # * percent (24%)
      # * by name (xx-small, x-small, small, medium, large, x-large, xx-large)
      #
      # @param [String] css size rule
      # @return [String] css size rule in ems
      # see http://www.websemantics.co.uk/resources/font_size_conversion_chart/
      def self.val_to_em(rule_value)
        # Convert CSS names to px or em values
        case rule_value
          when /smaller/  then "0.8em"
          when /larger/   then "1.2em"
          when /xx-small/ then "8px"
          when /x-small/  then "10px"
          when /small/    then "13px"
          when /medium/   then "16px"
          when /large/    then "18px"
          when /x-large/  then "24px"
          when /xx-large/ then "32px"
          else rule_value
        end
      end

      # CSS directives must be top levl
      # We namespace the css so these will bork
      # The easy way to handle is to remove
      # So loop through identifying directives and remove them an anything indented inside
      def remove_css_directives(sass)

        new_sass = ""
        directive_indent = nil

        # Go through the lines rewriting paths as appropriate
        sass.each_line do |line|
          line = SassLine.new(self, line, directive_indent)

          if line.inside_css_directive?
            next
          elsif line.is_css_directive?
            directive_indent = line.indent
          else
            directive_indent = nil
            new_sass += "%s\n" % line.to_s
          end
        end

        new_sass
      end


      # rewrite internal paths to normalized paths
      def update_paths(sass)
        sass.each_line do |line|
          line = SassLine.new(self, line)
          line.rewrite_paths if line.has_path?
          new_sass += "%s\n" % line.to_s
        end

        new_sass
      end


      # Convert all fonts to ems
      def convert_fonts(sass)
        out = ""
        sass.each_line do |line|
          line.gsub!(/(\s*)(word-spacing|letter-spacing|font-size|line-height|margin-[^\s]+|margin|padding-[\s]+|padding)\s*:(.*)/) do |m|
            #                 :spacing  :rule  :value
            m = "%s%s: %s" % [$1,       $2,    CSS.val_to_em($3)]
          end
          out << line
        end
        out
      end

  end

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