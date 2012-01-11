module Epub
  # Just a simple logger for debugging
  module Logger
    def log(str)
      if $VERBOSE || ENV['LIB_VERBOSE']
        puts str
      end
    end
  end
end