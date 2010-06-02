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
        routes(:victoria_to_haywards_heath).areas(all=false).sort.should == ['Haywards Heath', 'London']
      end
      
      it 'should return a unique list of the names of the parent localities/localities of the route stops if the route has no terminuses' do 
        routes(:number_807_bus).areas(all=false).sort.should == ["Annfield Plain", "South Moor", "Stanley"]
      end
      
    end
    
    it 'should return a unique list of the names of the parent localities/localities of the stops' do 
      routes(:victoria_to_haywards_heath).areas.sort.should == ["Clapham Junction", "Croydon", "Gatwick Airport", "Haywards Heath", "London"]
    end
    
  end
  
  describe 'when finding from attributes' do 
    
    it "should find a route described by it's terminuses" do 
      attributes = { :transport_mode_id => 6, 
                     :route_number => 'London to Haywards Heath', 
                     :area => '' }
      routes = Route.find_from_attributes(attributes)
      routes.should include(routes(:victoria_to_haywards_heath))
    end
    
  end
  
  describe 'when finding existing routes' do 
  
    it 'should include routes with the same number and one stop in common with the new route' do 
      route = Route.new(:number => '807', 
                        :transport_mode => transport_modes(:bus))
      route.route_operators.build(:operator => operators(:a_bus_company))
      new_stop = mock_model(Stop, :atco_code => 'xxxx', :stop_areas => [])
      route.route_segments.build(:from_stop => stops(:arch_ne), :to_stop => new_stop, :from_terminus => true)
      Route.find_existing_routes(route).should include(routes(:number_807_bus))
    end
    
    it 'should include routes with the same number, no stops in common, but one stop area in common with the new route and the same operator' do
      route = Route.new(:number => '807', :transport_mode => transport_modes(:bus))
      route.route_operators.build(:operator => operators(:a_bus_company))
      new_stop = mock_model(Stop, :atco_code => 'xxxx', :stop_areas => [])
      route.route_segments.build(:from_stop => stops(:arch_sw), 
                                 :to_stop => new_stop,
                                 :from_terminus => true,
                                 :to_terminus => false)
      Route.find_existing_routes(route).should include(routes(:number_807_bus))
    end
    
    it 'should not include routes with the same number, no stops in common, but one stop area in common with the new route and a different operator' do
      route = Route.new(:number => '807', :transport_mode => transport_modes(:bus))
      route.route_operators.build(:operator => operators(:another_bus_company))
      new_stop = mock_model(Stop, :atco_code => 'xxxx', :stop_areas => [])
      route.route_segments.build(:from_stop => stops(:arch_sw), 
                                 :to_stop => new_stop,
                                 :from_terminus => true,
                                 :to_terminus => false)
      Route.find_existing_routes(route).should_not include(routes(:number_807_bus))
    end
  end
  
  describe 'when finding existing train routes' do 
    
    before do 
      @route = Route.new(:transport_mode => transport_modes(:train))
      @route.route_operators.build(:operator => operators(:a_train_company))
      @existing_route = routes(:victoria_to_haywards_heath)
      @terminus_segments = @existing_route.route_segments.select do |segment| 
        segment.from_terminus? || segment.to_terminus? 
      end
    end
    
    it 'should include a route with the same terminuses and the same operator' do 
      @terminus_segments.each do |route_segment|
        @route.route_segments.build(:from_stop => route_segment.from_stop,
                                    :to_stop => route_segment.to_stop, 
                                    :from_terminus => route_segment.from_terminus?,
                                    :to_terminus => route_segment.to_terminus?)
      end
      @route.route_segments.build(:from_stop => stops(:victoria_station_one), 
                                  :to_stop => stops(:victoria_station_two), 
                                  :from_terminus => false,
                                  :to_terminus => false)
      Route.find_existing_train_routes(@route).should include(@existing_route)
    end
    
    it 'should not include an identical route with a different operator' do 
      @route.route_operators.clear
      @route.route_operators.build(:operator => operators(:another_train_company))
      @terminus_segments.each do |route_segment|
        @route.route_segments.build(:from_stop => route_segment.from_stop,
                                    :to_stop => route_segment.to_stop, 
                                    :from_terminus => route_segment.from_terminus?,
                                    :to_terminus => route_segment.to_terminus?)
      end
      Route.find_existing_train_routes(@route).should_not include(@existing_route)
    end
    
    it "should include a route that passes through the new route's terminuses and has the same operator" do 
      non_terminus_segments = @existing_route.route_segments.select do |segment| 
        !segment.from_terminus? && !segment.to_terminus? 
      end
      # new route starts and ends in the middle of the existing route
      new_route_start = non_terminus_segments.first
      new_route_end = non_terminus_segments.second
      @route.route_segments.build(:from_stop => new_route_start.from_stop, 
                                  :to_stop => new_route_start.to_stop, 
                                  :from_terminus => true,
                                  :to_terminus => false)
      @route.route_segments.build(:from_stop => new_route_end.from_stop, 
                                  :to_stop => new_route_end.to_stop, 
                                  :from_terminus => false,
                                  :to_terminus => true)                            
      Route.find_existing_train_routes(@route).should include(@existing_route)
    end
    
    it 'should include a route whose terminuses the new route stops at that has the same operator' do 
      # new route stops at the terminuses of the existing route but doesn't terminate there
      @terminus_segments.each do |route_segment|
        @route.route_segments.build(:from_stop => route_segment.from_stop,
                                    :to_stop => route_segment.to_stop, 
                                    :from_terminus => false,
                                    :to_terminus => false)
      end
      # and has a couple of non-matching terminuses
      @route.route_segments.build(:from_stop => stops(:victoria_station_two),
                                  :to_stop => stops(:victoria_station_one), 
                                  :from_terminus => true,
                                  :to_terminus => false)
                                  
      @route.route_segments.build(:from_stop => stops(:haywards_heath_station), 
                                  :to_stop => stops(:gatwick_airport_station), 
                                  :from_terminus => false, 
                                  :to_terminus => true)
      Route.find_existing_train_routes(@route).should include(@existing_route)
    end
  
  end
  
  
  describe 'when getting terminuses from a route name' do 
  
    it 'should get "London Victoria" and "Haywards Heath" from "London Victoria to Haywards Heath"' do 
      Route.get_terminuses("London Victoria to Haywards Heath").should == ['London Victoria', 'Haywards Heath']
    end
    
  end
  
  describe 'when adding a route' do 
  
    it 'should raise an exception if a route to be merged has problems associated with it' do
      Route.stub!(:find_existing).and_return([routes(:victoria_to_haywards_heath)])
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
      existing_route = routes(:victoria_to_haywards_heath)
      existing_route.route_operators.size.should == 1
      Route.stub!(:find_existing).and_return([existing_route])
      route_operator = RouteOperator.new(:operator => Operator.new)
      route = Route.new(:transport_mode_id => 5, 
                        :number => '43', 
                        :route_operators => [route_operator])
      Route.add!(route)
      existing_route.route_operators.size.should == 2
    end 
    
    it 'should not add duplicate route operator associations when merging overlapping routes' do 
      existing_route = routes(:victoria_to_haywards_heath)
      existing_operator = existing_route.operators.first
      existing_route.route_operators.size.should == 1
      Route.stub!(:find_existing).and_return([existing_route])
      route = Route.new(:transport_mode_id => 5, 
                        :number => '43', 
                        :route_operators => [RouteOperator.new(:operator => existing_operator)])
      Route.add!(route)
      existing_route.route_operators.size.should == 1
    end
    
    it 'should transfer route segment when merging overlapping routes' do 
      existing_route = routes(:victoria_to_haywards_heath)
      existing_route.route_segments.size.should == 4
      Route.stub!(:find_existing).and_return([existing_route])
      route_segment = mock_model(RouteSegment, :from_stop => Stop.new, 
                                               :to_stop => Stop.new,
                                               :from_terminus? => false,
                                               :to_terminus? => false,
                                               :destroy => true)
      route = Route.new(:transport_mode_id => 5, 
                        :number => '43', 
                        :route_segments => [route_segment])
      Route.add!(route)
      existing_route.route_segments.size.should == 5
    end
    
    it 'should not add duplicate route segments when merging overlapping routes' do 
      existing_route = routes(:victoria_to_haywards_heath)
      Route.stub!(:find_existing).and_return([existing_route])
      existing_route.route_segments.size.should == 4 
      route_segment = existing_route.route_segments.first
      route = Route.new(:transport_mode_id => 5, 
                        :number => '43')
      route.route_segments.build(:from_stop => route_segment.from_stop, 
                                 :to_stop => route_segment.to_stop, 
                                 :from_terminus => route_segment.from_terminus, 
                                 :to_terminus => route_segment.to_terminus)                  
      Route.add!(route)
      existing_route.route_segments.size.should == 4
    end
    
    it 'should not leave as terminuses stops that are terminuses in an existing route but not terminuses in a duplicate' do 
      existing_route = routes(:victoria_to_haywards_heath)
      Route.stub!(:find_existing).and_return([existing_route])
      existing_route_segment = existing_route.route_segments.detect{ |segment| segment.from_terminus? }
      existing_route_segment.from_terminus?.should be_true
      route_segment = mock_model(RouteSegment, :from_stop => existing_route_segment.from_stop, 
                                               :to_stop => existing_route_segment.to_stop,
                                               :from_terminus? => false, 
                                               :to_terminus? => false, 
                                               :destroy => true)
      route = Route.new(:transport_mode_id => 5, 
                        :number => '43', 
                        :route_segments => [route_segment])
      Route.add!(route)
      RouteSegment.find(existing_route_segment.id).from_terminus.should be_false
    end
    
  end

  
end
