# == Schema Information
# Schema version: 20100506162135
#
# Table name: routes
#
#  id                :integer         not null, primary key
#  transport_mode_id :integer
#  number            :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  type              :string(255)
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
  describe 'when giving its terminuses' do 
    
    it 'should return correct terminuses for an example route' do 
      routes(:victoria_to_haywards_heath).terminuses.should == [stops(:victoria_station_one), stops(:haywards_heath_station)]
    end
    
  end
  
  describe 'when giving its areas' do 
  
    describe 'when asked for only terminuses' do
      
      it 'should return a unique list of the names of the parent localities/localities of the terminuses' do 
        routes(:victoria_to_haywards_heath).areas(all=false).sort.should == ['Haywards Heath', 'Victoria']
      end
      
      it 'should return a unique list of the names of the parent localities/localities of the route stops if the route has no terminuses' do 
        routes(:number_807_bus).areas(all=false).sort.should == ["Annfield Plain", "South Moor", "Stanley"]
      end
      
    end
    
    it 'should return a unique list of the names of the parent localities/localities of the stops' do 
      routes(:victoria_to_haywards_heath).areas.sort.should == ["Clapham Junction", "Croydon", "Gatwick Airport", "Haywards Heath", "Victoria"]
    end
    
  end
  
  describe 'when finding from attributes' do 
  
    it 'should find any routes matching the number and transport mode id' do 
      attributes = { :transport_mode_id => 6, 
                     :route_number => '1F50', 
                     :area => '' }
      routes = Route.find_from_attributes(attributes)
      routes.should include(routes(:victoria_to_haywards_heath))
    end
    
    it 'should find any routes matching the number and transport mode id disregarding case' do 
      attributes = { :transport_mode_id => 6, 
                     :route_number => '1f50', 
                     :area => '' }
      routes = Route.find_from_attributes(attributes)
      routes.should include(routes(:victoria_to_haywards_heath))
    end
    
    
    it "should find a route described by it's terminuses" do 
      attributes = { :transport_mode_id => 6, 
                     :route_number => 'London Victoria to Haywards Heath', 
                     :area => '' }
      routes = Route.find_from_attributes(attributes)
      routes.should include(routes(:victoria_to_haywards_heath))
    end
    
    it 'should find a route that can be uniquely identified by number and area' do 
      attributes = { :transport_mode_id => 1, 
                     :route_number => '807', 
                     :area => 'aldershot' }
      routes = Route.find_from_attributes(attributes)
      routes.should include(routes(:aldershot_807_bus))
      routes.size.should == 1
    end
    
  end
  
  describe 'when finding routes by number and common stops' do 
  
    it 'should include routes with the same number and one stop in common with the new route' do 
      route = Route.new(:number => '807', :transport_mode => transport_modes(:bus))
      new_stop = mock_model(Stop, :atco_code => 'xxxx', :stop_areas => [])
      route.route_segments.build(:from_stop => stops(:arch_ne), :to_stop => new_stop, :from_terminus => true)
      Route.find_all_by_number_and_common_stop(route).should include(routes(:number_807_bus))
    end
    
    it 'should include routes with the same number, no stops in common, but one stop area in common with the new route' do
      route = Route.new(:number => '807', :transport_mode => transport_modes(:bus))
      new_stop = mock_model(Stop, :atco_code => 'xxxx', :stop_areas => [])
      route.route_segments.build(:from_stop => stops(:arch_sw), 
                                 :to_stop => new_stop,
                                 :from_terminus => true,
                                 :to_terminus => false)
      Route.find_all_by_number_and_common_stop(route).should include(routes(:number_807_bus))
    end
    
  end
  
  describe 'when finding routes by terminuses and stops' do 
    
    before do 
      @route = Route.new(:transport_mode => transport_modes(:train))
      routes(:victoria_to_haywards_heath).route_segments.each do |route_segment|
        @route.route_segments.build(:from_stop => route_segment.from_stop,
                                    :to_stop => route_segment.to_stop, 
                                    :from_terminus => route_segment.from_terminus,
                                    :to_terminus => route_segment.to_terminus)
      end
    end
    
    it 'should include a route with identical stops to the new route and the same terminuses' do 
      Route.find_all_by_terminuses_and_stop_set(@route).should include(routes(:victoria_to_haywards_heath))
    end
    
    it 'should include a route with a superset of the stops of the new route and the same terminuses' do 
      @route.route_segments.delete(@route.route_segments.second)
      Route.find_all_by_terminuses_and_stop_set(@route).should include(routes(:victoria_to_haywards_heath))
    end
  
  end
  
  
  describe 'when getting terminuses from a route name' do 
  
    it 'should get "London Victoria" and "Haywards Heath" from "London Victoria to Haywards Heath"' do 
      Route.get_terminuses("London Victoria to Haywards Heath").should == ['London Victoria', 'Haywards Heath']
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
    
    it 'should transfer route segment when merging overlapping routes' do 
      existing_route_segment = RouteSegment.new(:from_stop => Stop.new, 
                                                :to_stop => Stop.new,
                                                :from_terminus => false,
                                                :to_terminus => false)
      existing_route = Route.new(:number => '111')
      existing_route.route_segments << existing_route_segment
      Route.stub!(:find_existing).and_return([existing_route])
      route_segment = mock_model(RouteSegment, :from_stop => Stop.new, 
                                               :to_stop => Stop.new,
                                               :from_terminus => false,
                                               :to_terminus => false,
                                               :destroy => true)
      route = Route.new(:transport_mode_id => 5, 
                        :number => '43', 
                        :route_segments => [route_segment])
      Route.add!(route)
      existing_route.route_segments.size.should == 2
    end
    
    it 'should not add duplicate route segments when merging overlapping routes' do 
      existing_from_stop = mock_model(Stop, :atco_code => 'aaaaaa')
      existing_to_stop = mock_model(Stop, :atco_code => 'bbbbbb')
      existing_route_segment = mock_model(RouteSegment, :from_stop => existing_from_stop, 
                                                        :to_stop => existing_to_stop, 
                                                        :from_terminus? => false,
                                                        :to_terminus? => false)
      existing_route = mock_model(Route, :save! => true, :route_segments => [existing_route_segment])
      Route.stub!(:find_existing).and_return([existing_route])
      route_segment = mock_model(RouteSegment, :from_stop => existing_from_stop, 
                                               :to_stop => existing_to_stop,
                                               :destroy => true)
      route = Route.new(:transport_mode_id => 5, 
                        :number => '43', 
                        :route_segments => [route_segment])
      Route.add!(route)
      existing_route.route_segments.should == [existing_route_segment]
    end
    
    it 'should not make as terminuses stops that are terminuses in an existing route but not terminuses in a duplicate' do 
      existing_stop = mock_model(Stop, :atco_code => 'aaaaaa')
      new_stop = mock_model(Stop, :atco_code => 'bbbbbb')
      existing_route_segment = mock_model(RouteSegment, 
                                          :from_stop => existing_stop, 
                                          :to_stop => new_stop, 
                                          :from_terminus? => true,
                                          :to_terminus? => false)
      existing_route = mock_model(Route, :save! => true, :route_segments => [existing_route_segment])
      Route.stub!(:find_existing).and_return([existing_route])
      route_segment = mock_model(RouteSegment, :from_stop => existing_stop, 
                                               :to_stop => new_stop,
                                               :from_terminus? => false, 
                                               :to_terminus? => false, 
                                               :destroy => true)
      route = Route.new(:transport_mode_id => 5, 
                        :number => '43', 
                        :route_segments => [route_segment])
      existing_route_segment.should_receive(:from_terminus=).with(false)
      Route.add!(route)
    end
    
  end

  
end
