module Epub
  VERBOSE = false

  # Just a simple logger for debugging
  module Logger
    def log(str)
      if VERBOSE
        puts str
      end
    end
  end
end