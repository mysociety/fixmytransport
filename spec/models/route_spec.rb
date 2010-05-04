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
  
  describe 'when finding from attributes' do 
  
    it 'should find any routes matching the number and transport mode id' do 
      expected_id = routes(:victoria_to_haywards_heath).id
      attributes = { :transport_mode_id => 6, 
                     :route_number => '1F50' }
      routes = Route.find_from_attributes(attributes)
      routes.map{ |route| route.id }.include?(expected_id).should be_true
    end
    
    it 'should return instances of the base Route class' do 
      attributes = { :transport_mode_id => 6, 
                     :route_number => '1F50' }
      routes = Route.find_from_attributes(attributes)
      routes.each{ |route| route.class.should == Route }
    end
    
  end
  
  describe 'when finding routes by number and common stops' do 
  
    it 'should include routes with the same number and one stop in common with the new route' do 
      route = Route.new(:number => '807', :transport_mode => transport_modes(:bus))
      route.route_stops.build(:stop => stops(:arch_ne), :terminus => true)
      Route.find_all_by_number_and_common_stop(route).include?(routes(:number_807_bus)).should be_true
    end
    
    it 'should include routes with the same number, no stops in common, but one stop area in common with the new route' do
      route = Route.new(:number => '807', :transport_mode => transport_modes(:bus))
      route.route_stops.build(:stop => stops(:arch_sw), :terminus => true)
      Route.find_all_by_number_and_common_stop(route).include?(routes(:number_807_bus)).should be_true
    end
    
  end
  
  describe 'when adding a route' do 
  
    it 'should raise an exception if a route to be merged has problems associated with it' do
      Route.stub!(:find_existing).and_return([mock_model(Route)])
      route = Route.new(:problems => [mock_model(Problem)], :transport_mode_id => 5, :number => '43')
      lambda{ Route.add!(route) }.should raise_error(/Can't merge route with problems/)
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
      route_operator = RouteOperator.new(:operator => Operator.new)
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

  
end
