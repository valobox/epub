module Epub
  class Document < Base

    # @private
    attr_accessor :file, :path, :opf_xml


    # @param [String] path to an epub file, path can be either:
    #   * Directory of an extracted Epub
    #   * Epub file
    #   * Non existing path, in which case a new file is created
    def initialize(path)
      @path = path
      @file = build_file
      @opf_xml = file.read_xml(opf_path)

      # Reporting
      @start_time = Time.now
      @errors = []
    end


    # @overload extract(filepath)
    #   Unzips an Epub and Rezips it after the block exits
    #   @param [String] path to the Epub
    #   @yield [Epub::Document, epub_filepath] 
    # @overload extract(filepath, extract_path)
    #   @param [String] path to the Epub
    #   @param [String] directory path to extract to
    def self.extract(filepath, extract_path = nil)
      if block_given?
        Dir.mktmpdir do |outdir|
          ZipFile.unzip(filepath, outdir)
          yield self.new(outdir), outdir
          ZipFile.zip(outdir, filepath)
        end
      elsif extract_path
        ZipFile.unzip(filepath, extract_path)
      else
        raise "Incorrect arguments given"
      end
    end


    def standardize!
      begin
        # Standardize the urls
        toc.standardize!
        guide.standardize!
        manifest.standardize!

      rescue => ex
        log "failed to standardize\n #{ex.to_s}"
        raise ex
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
      begin
        create_base_directories!

        # Ensure all files are properly formatted
        standardize!

        # normalize the files
        toc.normalize!
        guide.normalize!
        manifest.normalize!
        
        clean_empty_dirs!

        report

      rescue => ex
        log "failed to normalize\n #{ex.to_s}"
        raise ex
      end


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
      @manifest ||= Manifest.new self
    end


    # Epub metadata accessor
    # @return [Epub::Metadata]
    def metadata
      @metadata ||= Metadata.new self
    end


    # Epub guide accessor
    # @return [Epub::Guide]
    def guide
      @guide ||= Guide.new self
    end


    # Epub spine accessor
    # @return [Epub::Spine]
    def spine
      @spine ||= Spine.new self
    end


    # Epub toc accessor
    # @return [Epub::Toc]
    def toc
      spine.toc
    end


    # Save a partial opf
    def save_opf!(doc_partial, xpath)
      log "saving updated opf"

      # Find where we're inseting into
      node = opf_xml.xpath(xpath, 'xmlns' => 'http://www.idpf.org/2007/opf').first

      if node
        # Because of <https://github.com/tenderlove/nokogiri/issues/391> we
        # create the new doc before we insert, else we get a default namespace
        # prefix
        doc_partial = Nokogiri::XML(doc_partial.to_s)
        node.replace(doc_partial.root)

        data = opf_xml.to_s

        file.write(opf_path, data)

        opf_xml
      end

    end


    def opf_path=(v)
      data = file.read("META-INF/container.xml")

      # Parse XML
      doc = Nokogiri::XML(data)
      raise "Error" if !doc

      # Edit the opf path
      node = doc.xpath("//xmlns:rootfile").first

      log "updating opf path from #{opf_path} to #{v}"
      node["full-path"] = v

      log "saving META-INF/container.xml"
      file.write("META-INF/container.xml", doc.to_s)
    end


    def opf_path
      doc = file.read_xml("META-INF/container.xml")
      doc.xpath("//xmlns:rootfile").first.attributes["full-path"].to_s
    end


    def opf_dirname
      Pathname.new(opf_path).dirname.to_s
    end


    def to_s
      ret = ""
      file.each do |entry|
        ret << entry.to_s
      end
      ret
    end


    # Add a line to the log file
    # @return boolean of write success
    def log(str, level = :log)
      initialize_log

      if level == :error
        report_error str
      end 

      log_string = "#{level.to_s.upcase}:: #{Time.now.strftime("%d/%m/%y %T")}:: #{str}"

      self.file.ammend(log_path, log_string)

      puts log_string if $VERBOSE || ENV['LIB_VERBOSE']
      true
    end

    # Read the epub log file
    def read_log
      file.read(log_path) if log_present?
    end


    private

      def log_path
        "log.txt"
      end


      def log_present?
        @file.exists?(log_path)
      end


      def initialize_log
        unless log_present?
          @file.write(log_path, "")
        end
      end


      def build_file
        case type
        when :zip
          ZipFile.new(path)
        when :filesystem
          FileSystem.new(path)
        when :nofile
          build_skeleton
        end
      end


      # Gets the type of the file passed to #new
      # @return [Symbol] type of file either [:filesystem, :zip, :nofile]
      def type
        if ::File.directory?(path)
          return :filesystem
        elsif ::File.file?(path)
          return :zip
        else
          return :nofile
        end
      end


      def create_base_directories!
        log "creating directories META-INF & OEBPS"
        file.mkdir "META-INF"
        file.mkdir "OEBPS"
      end


      def clean_empty_dirs!
        log "clean empty directories"
        file.clean_empty_dirs!
      end


      # Builds the skeleton Epub structure
      def build_skeleton
        raise "File not valid"
        file = ZipFile.new(path)
        file.mkdir "META-INF"
        file.mkdir "OEBPS"

        container_xml = <<-END.strip_heredoc
          <?xml version="1.0"?>
          <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
              <rootfiles>
                  <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
             </rootfiles>
          </container>
        END

        content_opf = <<-END.strip_heredoc
          <?xml version="1.0" encoding="UTF-8"?>
          <package xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookID" version="2.0">
              <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
              </metadata>
              <manifest></manifest>
              <spine toc="ncx"></spine>
          </package>
        END

        file.write("META-INF/container.xml", container_xml)
        file.write("OEBPS/content.opf",      content_opf)
        file
      end


      def report_error(str)
        @errors << str
      end


      def report
        {
          processing_time: @start_time - Time.now,
          errors: @errors
        }
      end

  end
end