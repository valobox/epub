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


    # Convert a css size rule value to ems, the supported formats are:
    # * point (24pt)
    # * pixels (24px)
    # * percent (24%)
    # * by name (xx-small, x-small, small, medium, large, x-large, xx-large)
    #
    # @param [String] css size rule
    # @return [String] css size rule in ems
    def self.val_to_em(rule_value)
      # Convert CSS px values
      rule_value = case rule_value        
        when /xx-small/ then "9px"
        when /x-small/  then "10px"
        when /small/    then "13px"
        when /medium/   then "16px"
        when /large/    then "18px"
        when /x-large/  then "24px"
        when /xx-large/ then "32px"
        else rule_value
      end
      
      number = rule_value.gsub("[0-9.]+", "\\1")
      
      # Use multipliers to convert to ems
      multiplier = case rule_value
        when /[0-9.]+pt\s*$/ then 1.0/12
        when /[0-9.]+px\s*$/ then 1.0/16
        when /[0-9.]+em\s*$/ then 1
        when /[0-9.]+%\s*$/  then 1.0/100
        else return rule_value
      end

      amt = (multiplier.to_f * number.to_f)
      return "%sem" % sprintf('%.2f', amt)
    end


    # TODO: Split this up into multiple methods
    # Normalizes the guide by flattening the file paths
    # 
    # @see Epub::File#normalize!
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
end