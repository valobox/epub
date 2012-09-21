require 'spec_helper'

describe Epub::CSS do

  let(:epub){ Epub::File.new(tmp_epub) }
  let(:css){ epub.manifest.css.first }

  before do
    setup_epub
  end

  it "should be an instance of Epub::CSS" do
    css.should be_a(Epub::CSS)
  end
  
  describe "standardize" do
    it "should move the css directives to the top of the file" do
      css.standardize
      puts css.to_s
      css.to_s.should_not =~ /\s+@/
    end

    it "should convert the font sizes" do
      css.to_s.should =~ /x-large/
      css.standardize
      css.to_s.should_not =~ /x-large/
    end

    it "should namespace the styles by the stylesheet filename" do
      css.standardize.should =~ /\.emerald \.textafterhead2/
    end

  end

  describe "standardize!" do

    it "should write the css back to the file" do
      css.standardize!
      epub.manifest.css.first.to_s.should_not =~ /x-large/
    end

  end

  describe "normalize" do


    it "should update the image paths" do
      css.normalize
      css.to_s.should =~ /url\(\"assets\/e308c4-cover\.jpg\"\)/
    end

    it "should update the font paths" do
      css.normalize
      css.to_s.should =~ /url\(assets\/d6b52b-MyriadProRegular\.otf\)/
    end

  end

  describe "normalize!" do

  end

end