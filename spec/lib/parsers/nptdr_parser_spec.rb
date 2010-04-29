require 'spec_helper'

describe Parsers::NptdrParser do 
  
  def example_file filename
    File.join(RAILS_ROOT, 'spec', 'examples', 'NPTDR', filename)
  end
  
  describe 'when parsing a TSV file of route data' do 
    
    before(:each) do 
      @transport_mode = mock_model(TransportMode, :route_type => "BusRoute")
      TransportMode.stub!(:find_by_name).with('Bus').and_return(@transport_mode)
      @stop = mock_model(Stop, :atco_code => 'xxxxx')
      Stop.stub!(:find_by_atco_code).and_return(@stop)
      @operator = mock_model(Operator, :code => 'ZZ')
      Operator.stub!(:find_or_create_by_code).and_return(@operator)
      @parser = Parsers::NptdrParser.new
      @routes = []
      @parser.parse_routes(example_file("routes.tsv")){ |route| @routes << route }
      @route = @routes.first
    end
    
    it 'should extract the route number' do 
      @route.number.should == '376'
    end
    
    it 'should set the transport mode id' do
      @route.transport_mode_id.should == @transport_mode.id
    end
    
    it 'should add stops to the route' do 
      @route.route_stops.first.stop.atco_code.should == 'xxxxx'
      @route.route_stops.second.stop.atco_code.should == 'xxxxx'
    end
    
    it 'should add operators to the route' do 
      @route.route_operators.first.operator.code.should == 'ZZ'
    end
    
    it 'should mark the route terminus stops' do 
      @route.route_stops.first.terminus?.should be_true
      @route.route_stops.last.terminus?.should be_true
      @route.route_stops.second.terminus?.should be_false
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
  
  describe 'when parsing a TSV file of operator data' do 
 
    before(:all) do 
      @parser = Parsers::NptdrParser.new
      @operators = []
      @parser.parse_operators(example_file("operators.tsv")){ |operator| @operators << operator }
    end
    
    it 'should extract the operator code' do 
      @operators.first.code.should == 'WP'
    end
    
    it 'should extract the name' do 
      @operators.first.name.should == 'Whippet Coaches'
    end
    
    it 'should extract the short name' do 
      @operators.first.short_name.should == 'Whippet'
    end
  
  end

end