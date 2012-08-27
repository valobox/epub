require 'spec_helper'

describe Epub::CSS do

  let(:epub){ Epub::File.new(tmp_epub) }
  let(:css){ epub.manifest.css.first }

  before do
    setup_epub
  end
  
  it "should inherit from Epub::Item" do
    
  end

  describe "normalize" do

    it "should remove the css directives" do
      css.normalize
      css.to_s.should_not =~ /@/
    end

    it "should update the internal paths" do
      css.normalize
      css.to_s.should_not =~ /src/
    end

    it "should convert the font sizes" do
      css.to_s.should =~ /x-large/
      css.normalize
      css.to_s.should_not =~ /x-large/
    end

  end

  describe "normalize!" do

    it "should write the css back to the file" do
      css.normalize!
      epub.manifest.css.first.to_s.should_not =~ /x-large/
    end
  end

end