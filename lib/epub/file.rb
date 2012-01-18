module Epub
  class File
    include Logger

    XML_NS = {
      'xmlns' => 'http://www.idpf.org/2007/opf'
    }

    attr_accessor :file

    def initialize(path)
      @path = path

      if type == :zip
        @file = ZipFile.new(path)
      else
        @file = FileSystem.new(path)
      end

      @opf_xml = @file.read_xml(opf_path)
    end

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

    # Compresses/minifies the epub, no params will produce compress the entire epub
    def compress!(*filter)
      manifest.items(*filter).each do |item|
        item.compress!
      end
    end


    ###
    # Part of the OPF
    ###
    def manifest
      Manifest.new opf_xml, self
    end

    def metadata
      Metadata.new opf_xml, self
    end

    def guide
      Guide.new opf_xml, self
    end

    def spine
      Spine.new opf_xml, self
    end

    def toc
      spine.toc
    end


    # Validates the epub and produces an error report
    #   * Validates manifest contains everything referenced
    #   * Validate css
    #   * Validate html and all paths are relative
    #   * Validate images are of the correct formats
    def valid?
      # TODO: Later improvement
      log "TODO"
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

      def type
        if ::File.file?(@path)
          return :zip
        else
          return :filesystem
        end
      end

  end
end