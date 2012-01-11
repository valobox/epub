module Epub
  module XML
    def xpath_node(root, xpath)
      node = root.xpath(xpath)
      if node
        if node.first
          return node.first
        end
      end
      return nil
    end
    
    # opts:
    #  :only_first: [boolean] returns only the first result
    #  :separator:  [boolean] string separtor for 1+ values defaults to ', '
    def xpath_content(root, xpath, opts={})
      opts[:separator] ||= ", "
      ret = []

      root.xpath(xpath).each do |n|
        ret << n.content.to_s
        return ret.join(opts[:separator]) if opts[:only_first]
      end

      if ret.length > 0
        return ret.join(opts[:separator])
      end
    
      return nil
    end
    
    def xpath_attr(root, xpath, attribute)
      node = xpath_node(root, xpath)
      if node
        return node.attributes[attribute].to_s
      end
      
      return nil
    end
  end
end