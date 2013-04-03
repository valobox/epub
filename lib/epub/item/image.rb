module Epub
  class Image < Item

    def initialize(epub, id) 
      super(epub, id)

      @type        = :image
      @normalized_dir = "OEBPS/assets"
    end


    def compress!
      log "compressing image #{filepath}"
    end
  end
end