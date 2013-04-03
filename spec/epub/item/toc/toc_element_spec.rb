require 'spec_helper'

describe Epub::TocElement do

  let(:epub){ Epub::Document.new(tmp_epub) }
  let(:toc){epub.toc}

  let(:xml){ '<navPoint id="navpoint-1" playOrder="1"><navLabel><text>Cover</text></navLabel><content src="html/01_cover.html"/></navPoint>' }
  let(:node){ Nokogiri::XML(xml) }

  subject(:element){ epub.toc.elements.first}

  before do
    toc.standardize
  end


  context "getting and setting attributes" do
    describe 'id' do
      it "should return the element name" do
        element.id.should == "navpoint-1"
      end
    end

    describe 'id=(id)' do
      it "should set the id node" do
        element.id = "fish"
        element.id.should == "fish"
      end
    end

    describe 'label' do
      it "should return the element name" do
        element.label.should == "Cover"
      end
    end

    describe 'label=(label)' do
      it "should set the label node" do
        element.label = "fish"
        element.label.should == "fish"
      end
    end

    describe 'src' do
      it "should return the src url" do
        element.src.should == "html/01_cover.html"
      end
    end

    describe 'src=(src)' do
      it "should set the src attribute" do
        element.label = "html/02_content.html"
        element.label.should == "html/02_content.html"
      end
    end

    describe 'url' do
      it "should return the escaped src" do
        element.stub(:content_node).and_return({"src" => "html/01 cover.html"})
        element.url.should == "html/01%20cover.html"
      end
    end

    describe 'play_order' do
      it "should return the element name" do
        element.play_order.should == 1
      end
    end

    describe 'play_order=(play_order)' do
      it "should set the play_order node" do
        element.play_order = 2
        element.play_order.should == 2
      end
    end
  end

  context "processing" do

    describe "standardize_url!" do
      it "should escape the src and save" do
        element.src = "one two three fish#poo"
        element.standardize_url!
        element.src.should == "one%20two%20three%20fish#poo"
      end

      it "should escape the src and save" do
        element.src = "one/two/three fish#poo"
        element.standardize_url!
        element.src.should == "one/two/three%20fish#poo"
      end
    end

    describe "normalize_url!" do
      it "should create a normalized src path" do
        element.normalize_url!
        element.src.should == "OEBPS/0d6339-01_cover.xhtml"
      end

      it "should keep the anchor and normalize the path" do
        element.src = "html/01_cover.html#fish"
        element.normalize_url!
        element.src.should == "OEBPS/0d6339-01_cover.xhtml#fish"
      end
    end

  end

  context "building hash output" do
    describe 'as_hash' do
      it "should return a hash" do
        element.to_hash.should == {id: "navpoint-1", label: "Cover", url: "html/01_cover.html", position: 1, children: []}
      end
    end

    describe 'self.as_hash' do
      it "should return an Array of toc elements" do
        Epub::TocElement.as_hash(epub.toc.elements).should be_an(Array)
      end

      it "should contain Hashes of toc elements" do
        Epub::TocElement.as_hash(epub.toc.elements).first.should == element.to_hash
      end
    end
  end

end