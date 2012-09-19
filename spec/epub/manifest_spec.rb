require "spec_helper"

describe Epub::Manifest do

  let(:epub){ Epub::File.new(tmp_epub) }
  let(:manifest){ epub.manifest }

  before do
    setup_epub
  end

  describe "manifest" do
    subject{manifest}

    it "should set up the manifest" do
      subject.should be_a(Epub::Manifest)
    end
  end

  describe "items" do
    subject{manifest.items}

    it "should be an array" do
      subject.should be_a(Array)
    end

    it "should contain an Epub::Item" do
      subject.first.should be_a(Epub::Item)
    end

    it "should contain an Epub::HTML" do
      subject.first.should be_a(Epub::HTML)
    end

    it "should take a block" do
      subject do |item|
        item.should be_a(Epub::Item)
      end
    end

    context "filters" do
      it "should only return html" do
        manifest.items(:html).collect(&:type).uniq.should == [:html]
      end

      it "should only return css" do
        manifest.items(:css).collect(&:type).uniq.should == [:css]
      end

      it "should only return image" do
        manifest.items(:image).collect(&:type).uniq.should == [:image]
      end

      it "should only return toc" do
        manifest.items(:toc).collect(&:type).uniq.should == [:toc]
      end

      it "should only return toc and html" do
        manifest.items(:toc, :html).collect(&:type).uniq.should include(:toc, :html)
      end
    end
  end

  describe "assets" do
    subject(:assets){ manifest.assets }

    it{ should be_a(Array) }

    it "should return :image, :css, :misc" do
      manifest.should_receive(:items).with(:image, :css, :misc)
      manifest.assets
    end
  end

  describe "images" do
    subject(:images){ manifest.images }

    it { should be_a(Array) }

    it "should return :image" do
      manifest.should_receive(:items).with(:image)
      manifest.images
    end
  end

  describe "html" do
    subject(:html){ manifest.html }

    it { should be_a(Array) }

    it "should return :html" do
      manifest.should_receive(:items).with(:html)
      manifest.html
    end
  end

  describe "css" do
    subject(:css){ manifest.css }

    it { should be_a(Array) }

    it "should return :css" do
      manifest.should_receive(:items).with(:css)
      manifest.css
    end
  end

  describe "misc" do
    subject(:misc){ manifest.misc }

    it { should be_a(Array) }

    it "should return :misc" do
      manifest.should_receive(:items).with(:misc)
      manifest.misc
    end
  end

  describe "[](id)" do
    it "should call find_for_id(id)" do
      id = "body002"
      manifest.should_receive(:item_for_id).with(id)
      manifest[id]
    end
  end

  describe "item_for_id(id)" do
    it "should call item_from_node" do
      id = "body002"
      # manifest.stub(:node_from_id).with(id)
      # manifest.should_receive(:item_from_node)
      manifest.item_for_id(id).should be_a(Epub::HTML)
    end
    it "should call node_from_id" do
      id = "body002"
      manifest.stub(:item_from_node)
      manifest.should_receive(:node_from_id).with(id)
      manifest.item_for_id(id)
    end
  end

  describe "normalize!" do

    before do
      manifest.stub(:normalize_item_contents)
      manifest.stub(:normalize_item_location)
      manifest.stub(:normalize_opf_path)
    end

    it "should call normalize_item_contents" do
      manifest.should_receive(:normalize_item_contents)
      manifest.normalize!
    end

    it "should call normalize_item_location" do
      manifest.should_receive(:normalize_item_location)
      manifest.normalize!
    end

    it "should call normalize_opf_path" do
      manifest.should_receive(:normalize_opf_path)
      manifest.normalize!
    end

    it "should normalize each item" do
      manifest.unstub(:normalize_item_contents)
      item = double("item")
      item.should_receive(:normalize!)
      manifest.stub(:items).with(any_args).and_return([item])
      manifest.normalize!
    end

    it "should normalize the manifest"

    it "should normalize the opf path"
  end

end