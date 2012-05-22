require 'spec_helper'

describe Parsers::NptgParser do

  def example_file filename
    File.join(RAILS_ROOT, 'spec', 'examples', 'NPTG', filename)
  end

  describe 'when parsing an example file of admin area data' do

    before(:all) do
      @parser = Parsers::NptgParser.new
      @admin_areas = []
      @parser.parse_admin_areas(example_file("AdminAreas.csv")){ |admin_area| @admin_areas << admin_area }
    end

    it 'should extract the name' do
      @admin_areas.first.name.should == 'Cambridgeshire'
    end

    it 'should extract the short name' do
      @admin_areas.first.short_name.should == 'Cambs'
    end

  end

  describe 'when parsing an example file of region data' do

    before(:all) do
      @parser = Parsers::NptgParser.new
      @regions = []
      @parser.parse_regions(example_file("Regions.csv")){ |region| @regions << region }
    end

    it 'should extract the name' do
      @regions.first.name.should == 'East Anglia'
    end

  end

  describe 'when parsing an example file of district data' do

    before(:all) do
      @parser = Parsers::NptgParser.new
      @districts = []
      @parser.parse_districts(example_file("Districts.csv")){ |district| @districts << district }
    end

    it 'should extract the name' do
      @districts.first.name.should == 'Cambridge'
    end

  end

  describe 'when parsing an example file of locality data' do

    before(:all) do
      @parser = Parsers::NptgParser.new
      @localities = []
      @parser.parse_localities(example_file("Localities.csv")){ |locality| @localities << locality }
    end

    it 'should extract the name' do
      @localities.first.name.should == 'Amesbury'
    end

  end

  describe 'when parsing an example file of locality link data' do

    before(:each) do
      @parser = Parsers::NptgParser.new
      @locality_links = []
      @parent_locality = mock_model(Locality)
      @child_locality = mock_model(Locality)
      Locality.stub!(:find_by_code).and_return(@parent_locality)
      Locality.stub!(:find_by_code).with('E0034965').and_return(@child_locality)
      @parser.parse_locality_links(example_file("LocalityHierarchy.csv")){ |locality_link| @locality_links << locality_link }
    end

    it 'should extract the localities and turn them into a locality link' do
      @locality_links.first.ancestor_id.should == @parent_locality.id
      @locality_links.first.descendant_id.should == @child_locality.id
    end

  end

end