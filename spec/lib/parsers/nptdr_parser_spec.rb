require 'spec_helper'

describe Parsers::NptdrParser do

  def example_file filename
    File.join(RAILS_ROOT, 'spec', 'examples', 'NPTDR', filename)
  end

  describe 'when parsing a TSV file of route data' do

    before(:each) do
      @transport_mode = mock_model(TransportMode, :route_type => "BusRoute", :name => 'Bus')
      TransportMode.stub!(:find_by_name).with('Bus').and_return(@transport_mode)
      @region = mock_model(Region, :name => "South East")
      @welsh_region = mock_model(Region, :name => 'Wales')
      @admin_area = mock_model(AdminArea, :region => @region)
      Region.stub!(:find_by_name).with('Wales').and_return(@welsh_region)
      @current_generation = mock('current generation')
      AdminArea.stub!(:current).and_return(@current_generation)
      @current_generation.stub!(:find_by_atco_code).and_return(@admin_area)
      @operator = mock_model(Operator, :name => 'A Test Operator')
      Operator.stub!(:find_all_current_by_nptdr_code).and_return([@operator])
      @stop = mock_model(Stop, :atco_code => 'xxxxx')
      Stop.stub!(:find_current_by_code).and_return{ |atco_code, options| mock_model(Stop, :atco_code => atco_code,
                                                                                  :other_code => nil,
                                                                                  :stop_type => 'BCS')}
      Stop.stub!(:find_current_by_code).with('eeeeeeee', anything()).and_return(nil)
      @parser = Parsers::NptdrParser.new
      @routes = []
      @missing = @parser.parse_routes(example_file("routes.tsv")){ |route| @routes << route }
      @route = @routes.first
    end

    it 'should extract the route number' do
      @route.number.should == '376'
    end

    it 'should set the transport mode id' do
      @route.transport_mode_id.should == @transport_mode.id
    end

    it 'should add stops to the route' do
      @route.journey_patterns.first.route_segments.first.from_stop.atco_code.should == 'aaaaaaaa'
      @route.journey_patterns.first.route_segments.first.to_stop.atco_code.should == 'bbbbbbbbb'
    end

    it 'should add an operator code to the route source admin area' do
      @route.route_source_admin_areas.first.operator_code.should == 'BL'
    end

    it 'should mark the route terminus stops' do
      @route.journey_patterns.first.route_segments.first.from_terminus?.should be_true
      @route.journey_patterns.first.route_segments.last.to_terminus?.should be_true
      @route.journey_patterns.first.route_segments.first.to_terminus?.should be_false
      @route.journey_patterns.first.route_segments.last.from_terminus?.should be_false
    end

    it 'should return a list of missing stops' do
      @missing.should == { "eeeeeeee" => ["BusRoute 376", "BusRoute 378"] }
    end

    it 'should return routes where missing stops have been skipped and the surrounding stops joined' do
      @routes.last.journey_patterns.first.route_segments.last.from_stop.atco_code.should == 'cccccccc'
      @routes.last.journey_patterns.first.route_segments.last.to_stop.atco_code.should == 'ddddddddd'
    end

  end

  describe 'when parsing a TSV file of stop data' do

    before(:all) do
      @parser = Parsers::NptdrParser.new
      @stops = []
      @parser.parse_stops(example_file("stops.tsv")){ |stop| @stops << stop }
    end

    it 'should extract the atco code' do
      @stops.first.atco_code.should == '3600XXX'
    end

    it 'should extract the common name' do
      @stops.first.common_name.should == 'Wells Bus Station'
    end

    it 'should extract the easting' do
      @stops.first.easting.should == 311122.0
    end

    it 'should extract the northing' do
      @stops.first.northing.should == 142223.0
    end

  end

end