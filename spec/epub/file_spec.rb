require 'spec_helper'

describe Epub::File do

  let(:epub_path){ tmp_epub }
  subject(:epub){ Epub::File.new(tmp_epub) }

  before do
    setup_epub
  end

  it "initializing should set the path" do
    epub.path.should == epub_path
  end

  it "should create a file" do
    epub.file.should be_a(Epub::ZipFile)
  end

end