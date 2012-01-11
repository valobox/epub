module Epub
  class Image < Item
    include Logger

    def initialize(filepath, epub)
      super(filepath, epub)

      @type        = :image
      @normalized_dir = "OEBPS/assets"
    end

    def compress!
      log "TODO: Image::compress!"
    end
  end
end