module Epub
  module Logger

    # http://www.spritle.com/blogs/2010/04/14/calling-methods-in-a-module-directly/
    # http://redcorundum.blogspot.com/2006/06/mixing-in-class-methods.html

    # @private
    module ClassMethods; end

    # @private
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    # @private
    module ClassMethods
      extend ClassMethods

      # Just a simple logger for debugging
      def log(str)
        if $VERBOSE || ENV['LIB_VERBOSE']
          puts str
        end
      end
    end


    # Logs to stdout if either ruby is in verbose mode `ruby -v` or the env
    # variable `LIB_VERBOSE=true` is set.
    #
    # @param [String] log message
    def log(str)
      ClassMethods.log(str)
      nil
    end
  end
end