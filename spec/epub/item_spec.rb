require 'spec_helper'

describe Epub::Item do

  let(:epub){ Epub::File.new(tmp_epub) }
  let(:item){ epub.spine.items.first }

  before do
    setup_epub
  end

  describe "read_xml" do
    it "should read and return the xml of the item"
  end

  describe "read" do
    it "should read the file text" do
      item.read.should =~ /html/
    end
  end

  describe "write(data)" do
    it "should write the data to the file" do
      text = "I am a fish"
      item.write(text)
      item.read.should == text
    end
  end

  describe "extract(path)" do
    it "should extract the epub to a path"
  end

  describe "filepath" do
    it "should return the filepath" do
      item.filepath.should == "html/01_cover.html"
    end
  end

  describe "filename(opts)" do
    it "should return the filename from the manifest" do
      item.filepath.should == "html/01_cover.html"
    end
  end

  describe "abs_filepath" do
    it "should return the filepath relative to the epub root" do
      item.abs_filepath.should == "OEBPS/html/01_cover.html"
    end
  end

  describe "get_item(rel_path)" do
    it "should return a Epub::Item" do
      item.get_item("002_alsoby.html").should be_a(Epub::Item)
    end

    it "should return nil if the relative file does not exist" do
      item.get_item("non_existant").should be_nil
    end
  end

  describe "normalized_hashed_path(opts)" do
    it "should be a string" do
      sleep 0.1 # takes time to unzip - should we use a callback?
      item.normalized_hashed_path.should == "OEBPS/0d6339-01_cover.xhtml"
    end

    it "should be return a relative path if given relative_to option" do
      sleep 0.1 # takes time to unzip - should we use a callback?
      item.normalized_hashed_path(relative_to: epub.opf_path).should == "0d6339-01_cover.xhtml"
    end
  end

  describe "normalize!" do

  end

  describe "compress!" do
  end

  describe "create_manifest_entry(href)" do
    it "should create a manifest entry from an href" do
      epub.manifest.should_receive(:add).with("html/peter.html")
      item.create_manifest_entry("peter.html")
    end
  end

  
end