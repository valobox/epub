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
      puts epub.read_log
    end

    it "should normalize the file when extracted", speed: :slow do
      Epub::File.extract(epub_path) do |epub|
        epub.normalize!.should be_true
      end
    end
  end

  describe "normalize_hrefs" do
    it "should standardize the escaping of href attributes" do
      epub.manifest.send :normalize_hrefs
      puts epub.manifest.to_s
    end
  end

end