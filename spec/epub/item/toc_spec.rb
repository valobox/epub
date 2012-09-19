require 'spec_helper'

describe Epub::Toc do

  let(:epub){ Epub::File.new(tmp_epub) }
  let(:toc){epub.toc}

  before :all do
    setup_epub
  end

  describe "as_hash" do


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

  describe "normalize" do

    it "should change the filepaths" do
      toc.normalize!
      toc.xml.should_not =~ /html\/01_cover.html/
      toc.xml.should =~ /0d6339-01_cover.xhtml/
    end

  end

  describe "xml" do
    it "should return a string" do
      toc.xml.should be_a(String)
    end
  end

end