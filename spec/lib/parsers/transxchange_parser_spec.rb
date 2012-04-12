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

  before do
    example_dir = File.join(RAILS_ROOT, 'spec', 'examples', 'TNDS')
    @file_pattern = File.join(example_dir, "*.xml")
    @example_file_path = File.join(example_dir, 'SVRYSDO005-20120130-80845.xml')
    @filename_conditions = ['filename = ?', @example_file_path]
    @index_file_path = File.join(example_dir, "index.txt")
  end

  describe 'when parsing an example file of TNDS style route data' do

    before do
      @parser = Parsers::TransxchangeParser.new
      @simple_file = example_file("SVRYSDO005-20120130-80845.xml")
      @combined_file = example_file("ea_20-3_-1-y08.xml")
      mock_operator = mock_model(Operator)
      Operator.stub!(:find_all_by_nptdr_code).and_return([mock_operator])
      @mock_region = mock_model(Region, :name => 'Yorkshire')
    end

    it 'should extract the number from a route' do
      routes = get_routes(@parser, [@simple_file, nil, nil, @simple_file, verbose=false, @mock_region])
      routes.first.number.should == '5'
    end

    it 'should set the region of a route' do
      routes = get_routes(@parser, [@simple_file, nil, nil, @simple_file, verbose=false, @mock_region])
      routes.first.region.should == @mock_region
    end

    it "should look for the stops referenced in a timing pattern associated with a section of the route's
        journey pattern" do
      Stop.should_receive(:find_by_code).with('370055370', {:includes => {:stop_area_memberships => :stop_area}})
      Stop.should_receive(:find_by_code).with('370055986', {:includes => {:stop_area_memberships => :stop_area}})
      routes = get_routes(@parser, [@simple_file, nil, nil, @simple_file, verbose=false, @mock_region])
    end

    it 'should create a route source model for the route recording the filename, line number, region, service
        code and operator code' do
      routes = get_routes(@parser, [@simple_file, nil, nil, @simple_file, verbose=false, @mock_region])
      routes.first.route_sources.size.should == 1
      route_source = routes.first.route_sources.first
      route_source.service_code.should == 'YSDO005'
      route_source.operator_code.should == 'RLB'
      route_source.line_number.should == 74
      route_source.filename.should == @example_file_path
    end

    it 'should merge as one route services with the same line name in the same file' do
      routes = get_routes(@parser, [@combined_file, nil, nil, @combined_file, verbose=false, @mock_region])
      routes.size.should == 1
      combined_route = routes.first
      combined_route.number.should == "3"
      combined_route.route_sources.size.should == 2
      first_source = combined_route.route_sources.first
      second_source = combined_route.route_sources.second
      first_source.line_number.should == 2321
      second_source.line_number.should == 2381
    end

    it 'should create an operator for the route based on the operator code' do
      mock_operator = mock_model(Operator)
      expected_arguments = [anything(), '027WP', @mock_region, anything()]
      Operator.stub!(:find_all_by_nptdr_code).with(*expected_arguments).and_return([mock_operator])
      routes = get_routes(@parser, [@combined_file, nil, nil, @combined_file, verbose=false, @mock_region])
      combined_route = routes.first
      combined_route.route_operators.size.should == 1
      combined_route.route_operators.first.operator.should == mock_operator
    end

  end

  describe 'when parsing an example directory of TNDS TransXChange XML files' do

    before do
      @parser = Parsers::TransxchangeParser.new
      @mock_region = mock_model(Region)
      Region.stub!(:find_by_name).and_return(nil)
      Region.stub!(:find_by_name).with('Yorkshire').and_return(@mock_region)
      Region.stub!(:find_by_name).with('East Anglia').and_return(@mock_region)
      @parser.stub!(:parse_routes)
      RouteSource.stub!(:find).with(:all, :conditions => anything()).and_return([])
    end

    it 'should not try to parse a file for which there is already an entry in the route sources table' do
      mock_route_source = mock_model(RouteSource)
      RouteSource.stub!(:find).with(:all, :conditions => anything()).and_return([mock_route_source])
      @parser.should_not_receive(:parse_routes)
      @parser.parse_all_tnds_routes(@file_pattern, @index_file_path, verbose=false, skip_loaded=true)
    end

    it 'should try to parse a file that does not have an entry in the route sources table' do
      @parser.should_receive(:parse_routes)
      @parser.parse_all_tnds_routes(@file_pattern, @index_file_path, verbose=false, skip_loaded=true)
    end

    it 'should look for and parse the index file' do
      @parser.should_receive(:parse_index)
      @parser.stub!(:region_hash).and_return({ 'SVRYSDO005-20120130-80845.xml' => 'Yorkshire',
                                               'ea_20-3_-1-y08.xml' => 'East Anglia' })
      @parser.parse_all_tnds_routes(@file_pattern, @index_file_path, verbose=false, skip_loaded=true)
    end

    it 'should look for the region of each file parsed in the index' do
      region_hash = mock('region_hash')
      @parser.stub!(:region_hash).and_return(region_hash)
      region_hash.should_receive(:[]).with('SVRYSDO005-20120130-80845.xml').and_return('Yorkshire')
      region_hash.should_receive(:[]).with('ea_20-3_-1-y08.xml').and_return('East Anglia')
      @parser.parse_all_tnds_routes(@file_pattern, @index_file_path, verbose=false, skip_loaded=true)
    end

  end

  describe 'when parsing an example index file for a zip of route data files' do

    before(:all) do
      @parser = Parsers::TransxchangeParser.new
    end

    it 'should raise an error if the index file cannot be found' do
      lambda{ @parser.parse_index(example_file('not_the_index.txt')) }.should raise_error()
    end

    it 'should return a hash of filenames to regions' do
      @parser.parse_index(example_file('index.txt'))
      @parser.region_hash['SVRYSDO005-20120130-80845.xml'].should == 'Yorkshire'
    end

  end
end