require 'spec_helper'

describe Epub::Metadata do

  subject(:epub){ Epub::Document.new(tmp_epub) }
    
  before do
    setup_epub
  end


  it "should retrieve the metadata" do
    epub.metadata.should be_a(Epub::Metadata)
  end

  describe "[]" do

    it "should retrive the title" do
      epub.metadata[:title].should == "Emerald City And Other Stories"
    end

    it "should retrive the isbn" do
      epub.metadata[:isbn].should == "9781780334646"
    end

    it "should retrive the creator" do
      epub.metadata[:creator].should == "Jennifer Egan"
    end
  end

  describe "[]=(thing)" do

    it "should set the title" do
      epub.metadata[:title] = "Test file"
      epub.metadata[:title].should == "Test file"
    end

    it "should set the ISBN" do
      epub.metadata[:isbn] = "9781780334640"
      epub.metadata[:isbn].should == "9781780334640"
    end

    it "should set the creator" do
      epub.metadata[:creator] = "peter pan"
      epub.metadata[:creator].should == "peter pan"
    end
  end

end