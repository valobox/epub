require 'spec_helper'

describe Epub::HTML do

  let(:epub_path){ tmp_epub }
  let(:epub){ Epub::File.new(tmp_epub) }
  let(:cover_html){ epub.manifest.item_for_id("cover") }
  let(:page_html){ epub.manifest.item_for_id("body005") }
  let(:copyright_html){ epub.manifest.item_for_id("body004") }

  before do
    setup_epub
  end

  describe "normalize" do
    it "should normalize the image src" do
      cover_html.normalize
      cover_html.to_s.should =~ /d8aed3.jpg/
    end

    it "should normalize the stylesheets" do
      cover_html.normalize
      cover_html.to_s.should =~ /3237cf.css/
    end

    it "should normalize the links" do
      page_html.normalize
      page_html.to_s.should =~ /a6b68a.xhtml/
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



end