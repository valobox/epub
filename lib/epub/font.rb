module Epub
  class Font
    # Convert css font string to a value in em's
    # Supported formats:
    #  - point (24pt)
    #  - pixels (24px)
    #  - ems (24em)
    #  - percent (24%)
    #  - by name (xx-small, x-small, small, medium, large, x-large, xx-large)
    # Returns:
    #  - ??em
    def self.css_to_ems(css_value)    
      # Convert CSS values
      css_value = case css_value        
        when /xx-small/ then "9px"
        when /x-small/  then "10px"
        when /small/    then "13px"
        when /medium/   then "16px"
        when /large/    then "18px"
        when /x-large/  then "24px"
        when /xx-large/ then "32px"
        else css_value
      end
      
      number = css_value.gsub("[0-9]+", "\\1")
      
      multiplier = case css_value
        when /[0-9]+pt\s*$/ then 1.0/12
        when /[0-9]+px\s*$/ then 1.0/16
        when /[0-9]+em\s*$/ then 1
        when /[0-9]+%\s*$/  then 1.0/100
        else return css_value
      end
    
      amt = (multiplier.to_f * number.to_f)
      
      return "%sem" % sprintf('%.2f', amt)
    end

  end
end