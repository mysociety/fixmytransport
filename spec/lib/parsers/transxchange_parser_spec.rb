require 'spec_helper'

describe Parsers::TransxchangeParser do 
  
  def example_file filename
    File.join(RAILS_ROOT, 'spec', 'examples', 'TNDS', filename)
  end
  
  def get_routes(parser, params)
    routes = []
    parser.parse_routes(*params){ |route| routes << route }
    routes
  end
  
  describe 'when parsing an example file of route data' do 
    
    before do 
      @parser = Parsers::TransxchangeParser.new
      @file = example_file("SVRYSDO005-20120130-80845.xml")
      Operator.stub!(:find_all_by_nptdr_code).and_return([])
      @mock_region = mock_model(Region)
    end
    
    it 'should extract the number from a route' do 
      routes = get_routes(@parser, [@file, nil, nil, nil, verbose=false, @mock_region])
      routes.first.number.should == '5'
    end
    
    it 'should set the region of a route' do 
      routes = get_routes(@parser, [@file, nil, nil, nil, verbose=false, @mock_region])
      routes.first.region.should == @mock_region
    end
    
    it "should look for the stops referenced in a timing pattern associated with a section of the route's 
        journey pattern" do 
      Stop.should_receive(:find_by_code).with('370055370', {:includes => {:stop_area_memberships => :stop_area}})
      Stop.should_receive(:find_by_code).with('370055986', {:includes => {:stop_area_memberships => :stop_area}})
      routes = get_routes(@parser, [@file, nil, nil, nil, verbose=false, @mock_region])
    end
  
  end
  
  describe 'when parsing an index file for a zip of route data files' do 
    
    before(:all) do 
      @parser = Parsers::TransxchangeParser.new
      @parser.parse_index(example_file('index.txt'))
    end
  
    it 'should return a hash of filenames to regions' do 
      @parser.region_hash['SVRYSDO005-20120130-80845.xml'].should == 'Yorkshire'
    end
    
  end
end