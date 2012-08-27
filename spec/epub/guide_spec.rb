require 'spec_helper'

describe Epub::Guide do

  let(:epub_path){ tmp_epub }
  let(:epub){ Epub::File.new(tmp_epub) }
  subject(:guide){ epub.guide }

  before do
    setup_epub
  end

  describe "normalize!" do
    it "should normalize the guide" do
      guide.should_receive(:normalize)
      guide.stub(:save)
      guide.normalize!
    end

    it "should save the guide" do
      guide.stub(:normalize)
      guide.should_receive(:save)
      guide.normalize!
    end
  end

  describe "normalize" do
    it "should update the hrefs" do
      guide.normalize
      guide.to_s.should =~ /0d6339-01_cover.xhtml/
    end
  end

  describe "save" do
    it "should save the data" do
      epub.should_receive(:save_opf!)
      guide.save
    end
  end


end