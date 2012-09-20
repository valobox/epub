require 'spec_helper'

describe Epub::File do

  let(:epub_path){ tmp_epub }
  subject(:epub){ Epub::File.new(tmp_epub) }

  before do
    setup_epub
  end

  it "initializing should set the path" do
    epub.path.should == epub_path
  end

  it "should create a file" do
    epub.file.should be_a(Epub::ZipFile)
  end

  describe "normalize!" do
    it "should normalize the file when zipped", speed: :slow do
      epub.normalize!.should be_true
    end

    it "should normalize the file when extracted", speed: :slow do
      Epub::File.extract(epub_path) do |epub|
        epub.normalize!.should be_true
      end
    end

    Dir["spec/fixtures/test_files/*.epub"].each do |epub_path|
      it "should normalize the file #{File.basename(epub_path)}", speed: :slow do
        setup_epub(epub_path)
        Epub::File.extract(tmp_epub) do |epub|
          epub.normalize!.should be_true
        end
      end
    end
  end

  describe "standardize_hrefs" do
    it "should standardize the escaping of href attributes" do
      epub.manifest.send :standardize_hrefs
    end
  end

  context "logger" do
    describe "log(str)" do
      it "should write a line to the log file" do
        epub.log "fishing!"
        epub.read_log.should =~ /fishing/
      end

      it "should persist the log" do
        epub.log "fishing!"
        epub2 = Epub::File.new(tmp_epub)
        epub2.read_log.should =~ /fishing/
      end

      it "should initialize a log if none is present" do
        epub.file.exists?("log.txt").should be_false
        epub.log "fishing!"
        epub.file.exists?("log.txt").should be_true
      end
    end

    describe "read_log" do
      it "should read the contents of the log file" do
        epub.log "fishing"
        epub.read_log.should =~ /fishing/
      end

      it "should return false if no log is present?" do
        epub.read_log.should be_false
      end
    end
  end

end