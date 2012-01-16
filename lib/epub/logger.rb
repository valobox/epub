module Epub
  module Logger

    # http://www.spritle.com/blogs/2010/04/14/calling-methods-in-a-module-directly/
    # http://redcorundum.blogspot.com/2006/06/mixing-in-class-methods.html

    module ClassMethods; end

    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      extend ClassMethods

      # Just a simple logger for debugging
      def log(str)
        if $VERBOSE || ENV['LIB_VERBOSE']
          puts str
        end
      end
    end

    def log(str)
      ClassMethods.log(str)
    end
  end
end