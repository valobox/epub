require 'spec_helper'

describe Epub::Toc do

  let(:epub){ Epub::File.new(tmp_epub) }
  let(:toc){epub.toc}

  before do
    setup_epub
  end

  describe "as_hash" do

    before do
      toc.standardize
    end


    it "should return an array" do
      toc.as_hash.should be_a(Array)
    end

    it "should contain hashes" do
      toc.as_hash.first.should be_a(Hash)
    end

    context "each hash" do

      let(:toc_hash){ toc.as_hash.first }

      it "should contain a label" do
        toc_hash[:label].should == "Cover"
      end

      it "should contain a url" do
        toc_hash[:url].should == "html/01_cover.html"
      end

      it "should contain a position" do
        toc_hash[:position].should == 1
      end

      it "should contain a child array" do
        toc_hash[:children].should == []
      end

    end
  end

  describe "standardize" do

    it "should " do
      toc.standardize
    end

  end

  describe "normalize" do

    before do
      toc.standardize
    end

    it "should change the filepaths" do
      toc.normalize!
      toc.xml.should_not =~ /html\/01_cover.html/
      toc.xml.should =~ /0d6339-01_cover.xhtml/
    end

  end

  describe "xml" do

    before do
      toc.standardize
    end
    
    it "should return a string" do
      toc.xml.should be_a(String)
    end
  end

  describe "elements" do
    it "should find elements with a ncx namespace in the toc"

    it "should find elements with a ncx:ncx namepace in the toc"
  end

end