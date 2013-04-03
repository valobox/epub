require 'spec_helper'

describe Epub::HTML do

  let(:epub){ Epub::Document.new(tmp_epub) }
  let(:cover_html){ epub.manifest.item_for_id("cover") }
  let(:page_html){ epub.manifest.item_for_id("body005") }
  let(:copyright_html){ epub.manifest.item_for_id("body004") }

  before do
    setup_epub
  end

  describe "standardize" do
    it "should ensure the html has a body tag" do
      page_html.standardize.should =~ /\<body/
    end

    it "should ensure the html has an html tag" do
      page_html.standardize.should =~ /\<html/
    end

    it "should remove any scripts from the page" do
      page_html.standardize.should_not =~ /\<script/
    end

    it "should namespace the html by adding the stylesheet names as classes to the body node" do
      page_html.standardize.should =~ /\<body class=\"epub_emerald\"/
    end
  end

  describe "normalize" do
    it "should normalize the image src" do
      cover_html.normalize
      cover_html.to_s.should =~ /d8aed3-cover_ader.jpg/
    end

    it "should normalize the stylesheets" do
      cover_html.normalize
      cover_html.to_s.should =~ /3237cf-emerald.css/
    end

    it "should normalize the links" do
      page_html.normalize
      page_html.to_s.should =~ /a6b68a-007_c1.xhtml/
    end

    it "should not touch external links" do
      copyright_html.normalize
      copyright_html.to_s.should =~ /http\:\/\/www\.constablerobinson\.com/
    end

    it "should add an item to the manifest for missing items"

  end

  describe "save" do
    it "should write the doc" do
      html = double("doc")
      page_html.stub(:html).and_return(html)
      page_html.should_receive(:write).with(html).and_return(true)
      page_html.save
    end

  end

  context "html" do
    let(:html){ "<html>Hello World</html>" }

    describe "html=(html)" do

      it "should set the html" do
        page_html.html = html
        page_html.html.should == html
      end

      it "should enable saving of the html" do
        page_html.html = html
        page_html.save
        page_html.read.should == html
      end
    end

    describe "html" do
      it "should fetch the html var when present" do
        page_html.html = html
        page_html.html.should == html
      end

      it "should build the html from the xmldoc if not present" do
        page_html.html.should == page_html.to_s
      end
    end
  end


end