module Epub
  class Font
    # Convert a css size rule to ems, the supported formats are:
    # * point (24pt)
    # * pixels (24px)
    # * percent (24%)
    # * by name (xx-small, x-small, small, medium, large, x-large, xx-large)
    #
    # @param [String] css size rule
    # @return [String] css size rule in ems
    def self.css_to_ems(rule_value)    
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
      
      number = rule_value.gsub("[0-9]+", "\\1")
      
      # Use multipliers to convert to ems
      multiplier = case rule_value
        when /[0-9]+pt\s*$/ then 1.0/12
        when /[0-9]+px\s*$/ then 1.0/16
        when /[0-9]+em\s*$/ then 1
        when /[0-9]+%\s*$/  then 1.0/100
        else return rule_value
      end
    
      amt = (multiplier.to_f * number.to_f)
      return "%sem" % sprintf('%.2f', amt)
    end

  end
end