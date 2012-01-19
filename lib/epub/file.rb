module Epub
  class File
    include Logger

    # @private
    XML_NS = {
      'xmlns' => 'http://www.idpf.org/2007/opf'
    }

    # @private
    attr_accessor :file

    # @param [String] path to an epub file, path can be either:
    #   * Directory of an extracted Epub
    #   * Epub file
    #   * Non existing path, in which case a new file is created
    def initialize(path)
      @path = path

      case type
      when :zip
        @file = ZipFile.new(path)
      when :filesystem
        @file = FileSystem.new(path)
      when :nofile
        raise "File not valid"
        @file = ZipFile.new(path)
        build_skeleton
      end

      @opf_xml = @file.read_xml(opf_path)
    end


    # @overload extract(filepath)
    #   Unzips an Epub and Rezips it after the block exits
    #   @param [String] path to the Epub
    #   @yield [Epub::File, epub_filepath] 
    # @overload extract(filepath, extract_path)
    #   @param [String] path to the Epub
    #   @param [String] directory path to extract to
    def self.extract(filepath, extract_path=nil)
      if block_given?
        Dir.mktmpdir do |outdir|
          ZipFile.unzip(filepath, outdir)
          yield Epub::File.new(outdir), outdir
          ZipFile.zip(outdir, filepath)
        end
      elsif extract_path
        ZipFile.unzip(filepath, extract_path)
      else
        raise "Incorrect arguments given"
      end
    end


    # Flattens the directory structure, for example this:
    #
    #  /
    #  |-- META-INF
    #  |   `-- container.xml
    #  |-- mimetype
    #  `-- OEBPS
    #      |-- random_dir1
    #          |-- chA.css
    #          |-- ch01.html
    #          |-- ch02.html
    #          |-- image.jpg
    #      |-- random_dir2
    #          |-- chB.css
    #          |-- ch03.html
    #          |-- ch04.html
    #          |-- image.jpg
    #      |-- toc.ncx
    #      |-- content.opf
    #
    # Becomes:
    #
    #  /
    #  |-- META-INF
    #  |   `-- container.xml
    #  |-- mimetype
    #  `-- OEBPS
    #      |-- content.opf
    #      |-- content
    #          |-- 899ee1.css  (was chA.css)
    #          |-- f54ff6.css  (was chB.css)
    #          |-- c4b944.html (was ch01.html)
    #          |-- 4e895b.html (was ch02.html)
    #          |-- 89332e.html (was ch03.html)
    #          |-- c50b75.html (was ch04.html)
    #          |-- toc.ncx
    #          |-- assets
    #              |-- 5a17aa.jpg (was image.jpg)
    #              |-- b50b4b.jpg (was image.jpg)
    #
    # *NOTE:* the filenames above are a md5 hash of there original location
    #
    def normalize!
      # Prep
      log "preping"
      @file.mkdir "META-INF"
      @file.mkdir "OEBPS"

      log "toc.normalize!"
      toc.normalize!

      log "guide.normalize!"
      guide.normalize!

      log "manifest.normalize!"
      manifest.normalize!

      log "finalize"
      @file.clean_empty_dirs!
    end


    # Compresses/minifies the epub
    # @param [Array] filter of what to compress @see Epub::Manifest.items for
    #                filter options
    def compress!(*filter)
      manifest.items(*filter).each do |item|
        item.compress!
      end
    end


    # Epub manifest accessor
    # @return [Epub::Manifest]
    def manifest
      Manifest.new self
    end

    # Epub metadata accessor
    # @return [Epub::Metadata]
    def metadata
      Metadata.new self
    end

    # Epub guide accessor
    # @return [Epub::Guide]
    def guide
      Guide.new self
    end

    # Epub spine accessor
    # @return [Epub::Spine]
    def spine
      Spine.new self
    end

    # Epub toc accessor
    # @return [Epub::Toc]
    def toc
      spine.toc
    end


    # Save a partial opf
    def save_opf!(doc_partial, xpath)
      file.write(opf_path) do |f|
        doc = opf_xml

        # Find where we're inseting into
        node = doc.xpath(xpath, 'xmlns' => XML_NS['xmlns']).first

        # Because of <https://github.com/tenderlove/nokogiri/issues/391> we
        # create the new doc before we insert, else we get a default namespace
        # prefix
        doc_partial = Nokogiri::XML(doc_partial.to_s)
        node.replace(doc_partial.root)
        
        data = doc.to_s
        f.puts data

        @opf_xml = doc
      end
    end


    def opf_path=(v)
      data = file.read("META-INF/container.xml")

      # Parse XML
      doc = Nokogiri::XML(data)
      raise "Error" if !doc

      # Edit the opf path
      node = doc.xpath("//xmlns:rootfile").first
      node["full-path"] = v

      file.write("META-INF/container.xml") do |f|
        f.puts doc.to_s
      end
    end


    def opf_path
      doc = @file.read_xml("META-INF/container.xml")
      doc.xpath("//xmlns:rootfile").first.attributes["full-path"].to_s
    end


    def opf_xml
      @opf_xml
    end


    def to_s
      ret=""
      file.each do |entry|
        ret << entry.to_s
      end
      ret
    end


    private

      # Gets the type of the file passed to #new
      # @return [Symbol] type of file either [:filesystem, :zip, :nofile]
      def type
        if ::File.directory?(@path)
          return :filesystem
        elsif ::File.file?(@path)
          return :zip
        else
          return :nofile
        end
      end


    # Builds the skeleton Epub structure
    def build_skeleton
      @file.mkdir "META-INF"
      @file.mkdir "OEBPS"

      container_xml = <<END
<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
    <rootfiles>
        <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
   </rootfiles>
</container>
END

      content_opf = <<END
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookID" version="2.0">
    <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
    </metadata>
    <manifest></manifest>
    <spine toc="ncx"></spine>
</package>
END

      @file.write("META-INF/container.xml", container_xml)
      @file.write("OEBPS/content.opf",      content_opf)
      nil
    end

  end
end