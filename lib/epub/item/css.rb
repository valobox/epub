require "yui/compressor"
require "sass"
require 'tempfile'

module Epub
  class CSS < Item

    def initialize(filepath, epub)  
      super(filepath, epub)

      @type        = :css
      @normalized_dir = "OEBPS"
    end


    def normalize!
      # Read the css
      data = read

      sass = css_to_sass(data)

      # Resolve the images in the sass to there new location
      new_sass = ""

      remove_on_condition = nil
      directive_indent = -1
      sass.each_line do |line|
        line.chomp!

        # Get the indent size
        indent = line.sub(/^(\s+).*$/, "\\1").size

        # Remove if the last indent was a directive
        if remove_on_condition
          if indent > directive_indent
            next
          end
        end

        # If its a css directive remove it!
        if line =~ /^\s+@/
          directive_indent = indent
          remove_on_condition = true
          next
        end

        remove_on_condition = false

        # Grab all the url('path') definitions
        if line =~ /url\(.*\)/
          # Split it up into its parts
          line.gsub!(/(url\(["']?)(.+?)(["']?\))/) do |m|
            # Array for the new rule
            new_rule = [$1, nil, $3]
            src = $2

            # Check its not an external url
            if src !~ /^http[s]?:\/\// && src && src != ''
              # Delete any anchors (just incase)
              src = src.sub(/^(.*)\#$/, "$1")

              # Build the filename
              src_item = get_item(src)
              new_rule[1] = src_item.normalized_hashed_path(:relative_to => self)

              # override the original string
              m.replace new_rule.join
            end
          end
        end
        new_sass += "%s\n" % line
      end

      sass = new_sass

      sass = convert_fonts(sass)

      # Parse SASS
      engine = Sass::Engine.new(sass)

      # Render CSS and add it to the string
      css = engine.render

      write(css)
    end


    def compress!
      data = read
      compressor = YUI::CssCompressor.new
      compressor.compress(data)

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


      # Convert all fonts to ems
      def convert_fonts(sass)
        out = ""
        sass.each_line do |line|
          line.gsub!(/(\s*)(word-spacing|letter-spacing|font-size|line-height)\s*:(.*)/) do |m|
            #                 :spacing  :rule  :value
            m = "%s%s: %s" % [$1,       $2,    Font.css_to_ems($3)]
          end
          out += line
        end
        out
      end
  end
end