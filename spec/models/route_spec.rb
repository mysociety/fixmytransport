# == Schema Information
# Schema version: 20100420102749
#
# Table name: routes
#
#  id                :integer         not null, primary key
#  transport_mode_id :integer
#  number            :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#

require 'spec_helper'

describe Route do

  fixtures :transport_modes, :stops, :stop_areas, :routes, :route_stops, :stop_area_memberships

  before(:each) do
    @valid_attributes = {
      :transport_mode_id => 1,
      :number => "value for number"
    }
  end

  it "should create a new instance given valid attributes" do
    route = Route.new(@valid_attributes)
    route.valid?.should be_true
  end
  
  describe 'when adding a route' do 
  
    it 'should raise an exception if a route to be merged has problems associated with it' do
      Route.stub!(:find_existing).and_return([mock_model(Route)])
      route = Route.new(:problems => [mock_model(Problem)], :transport_mode_id => 5, :number => '43')
      lambda{ Route.add!(route) }.should raise_exception(/Can't merge route with problems/)
    end
    
    it 'should save the route if no existing routes are found' do 
      Route.stub!(:find_existing).and_return([])
      route = Route.new(:transport_mode_id => 5, :number => '43')
      route.should_receive(:save!)
      Route.add!(route)
    end
    
    it 'should transfer route operator associations when merging overlapping routes' do 
      existing_route_operator = RouteOperator.new
      existing_route_operator.operator = Operator.new
      existing_route = Route.new(:number => '111')
      existing_route.route_operators << existing_route_operator
      Route.stub!(:find_existing).and_return([existing_route])
      route_operator = mock_model(RouteOperator, :operator => Operator.new, :destroy => true)
      route = Route.new(:transport_mode_id => 5, 
                        :number => '43', 
                        :route_operators => [route_operator])
      Route.add!(route)
      existing_route.route_operators.size.should == 2
    end 
    
    it 'should not add duplicate route operator associations when merging overlapping routes' do 
      operator = Operator.new
      route_operator = RouteOperator.new(:operator => operator)
      existing_route = Route.new(:number => '111')
      existing_route.route_operators << route_operator
      Route.stub!(:find_existing).and_return([existing_route])
      route = Route.new(:transport_mode_id => 5, 
                        :number => '43', 
                        :route_operators => [route_operator])
      Route.add!(route)
      existing_route.route_operators.should == [route_operator]
    end
    
    it 'should transfer route stops when merging overlapping routes' do 
      existing_route_stop = RouteStop.new(:stop => Stop.new)
      existing_route = Route.new(:number => '111')
      existing_route.route_stops << existing_route_stop 
      Route.stub!(:find_existing).and_return([existing_route])
      route_stop = mock_model(RouteStop, :stop => Stop.new, 
                                         :terminus => false,
                                         :destroy => true)
      route = Route.new(:transport_mode_id => 5, 
                        :number => '43', 
                        :route_stops => [route_stop])
      Route.add!(route)
      existing_route.route_stops.size.should == 2
    end
    
    it 'should not add duplicate route stops when merging overlapping routes' do 
      existing_stop = mock_model(Stop, :atco_code => 'aaaaaa')
      existing_route_stop = mock_model(RouteStop, :stop => existing_stop, :terminus? => false)
      existing_route = mock_model(Route, :save! => true, :route_stops => [existing_route_stop])
      Route.stub!(:find_existing).and_return([existing_route])
      route_stop = mock_model(RouteStop, :stop => existing_stop, :destroy => true)
      route = Route.new(:transport_mode_id => 5, 
                        :number => '43', 
                        :route_stops => [route_stop])
      Route.add!(route)
      existing_route.route_stops.should == [existing_route_stop]
    end
    
    it 'should not make as terminuses stops that are terminuses in an existing route but not terminuses in a duplicate' do 
      existing_stop = mock_model(Stop, :atco_code => 'aaaaaa')
      existing_route_stop = mock_model(RouteStop, :stop => existing_stop, :terminus? => true)
      existing_route = mock_model(Route, :save! => true, :route_stops => [existing_route_stop])
      Route.stub!(:find_existing).and_return([existing_route])
      route_stop = mock_model(RouteStop, :stop => existing_stop, :terminus? => false, :destroy => true)
      route = Route.new(:transport_mode_id => 5, 
                        :number => '43', 
                        :route_stops => [route_stop])
      existing_route_stop.should_receive(:terminus=).with(false)
      Route.add!(route)
    end
    
  end
  
  describe 'when finding existing routes' do 
  
    it 'should include in the results returned a route with the same number, mode of transport and stop codes' do 
      attributes = { :number => '1F50', 
                     :transport_mode_id => 5, 
                     :stop_codes => ['9100VICTRIC', '9100CLPHMJC', '9100ECROYDN', '9100GTWK', '9100HYWRDSH'] }
      Route.find_existing(attributes).include?(routes(:victoria_to_haywards_heath)).should be_true
    end
    
  end
  
end
