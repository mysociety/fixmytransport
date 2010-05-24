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
require 'route_spec_helper'

describe TrainRoute do
  
  describe 'when finding existing routes' do 
    
    it 'should include in the results returned a route with the same mode of transport whose stops are a subset of the new route' do 
      atco_codes = ['9100VICTRIC', '9100CLPHMJC', '9100ECROYDN', '9100GTWK', '9100NEW', '9100HYWRDSH'] 
      route = TrainRoute.new(:number => '1F54', 
                             :transport_mode_id => 6)
      add_stops_from_list route, atco_codes
      TrainRoute.find_existing(route).include?(routes(:victoria_to_haywards_heath)).should be_true
    end
    
    it 'should include in the results returned a route with the same mode of transport whose stops are a superset of the new route' do
      atco_codes = ['9100VICTRIC', '9100CLPHMJC', '9100ECROYDN', '9100HYWRDSH'] 
      route = TrainRoute.new(:number => '1F58', 
                             :transport_mode_id => 6)
      add_stops_from_list route, atco_codes
      TrainRoute.find_existing(route).include?(routes(:victoria_to_haywards_heath)).should be_true
    end

  end
  
  describe 'when adding a route' do 
  
    it 'should merge a route with the same stops and terminuses' do 
      @route = TrainRoute.new(:transport_mode => transport_modes(:train))
      routes(:victoria_to_haywards_heath).route_segments.each do |route_segment|
        @route.route_segments.build(:from_stop => route_segment.from_stop, 
                                    :to_stop => route_segment.to_stop, 
                                    :from_terminus => route_segment.from_terminus,
                                    :to_terminus => route_segment.to_terminus)
      end
      TrainRoute.add!(@route)
      @route.id.should be_nil
    end
    
    it 'should merge a route with the same stops and terminuses that visits a stop twice' do 
      @route = TrainRoute.new(:transport_mode => transport_modes(:train))
      routes(:victoria_to_haywards_heath).route_segments.create(:from_stop => stops(:haywards_heath_station), 
                                                                :to_stop => stops(:victoria_station_one),
                                                                :from_terminus => false,
                                                                :to_terminus => false)
      routes(:victoria_to_haywards_heath).route_segments.each do |route_segment|
        @route.route_segments.build(:from_stop => route_segment.from_stop, 
                                    :to_stop => route_segment.to_stop, 
                                    :from_terminus => route_segment.from_terminus,
                                    :to_terminus => route_segment.to_terminus)
      end
      TrainRoute.add!(@route)
      @route.id.should be_nil
    end
    
  end
  
  describe 'description' do
  
    it 'should be of the form "Train route between Haywards Heath and London Victoria"' do 
      route = routes(:victoria_to_haywards_heath)
      route.description.should == 'Train route between Haywards Heath and London Victoria'
    end
    
  end
  
  describe 'name' do 
  
    it 'should be of the form "Train route between Haywards Heath and London Victoria"' do 
      route = routes(:victoria_to_haywards_heath)
      route.name.should == 'Train route between Haywards Heath and London Victoria'
    end
    
    describe 'when given a stop to start from' do 
      
      describe 'if the stop is not a terminus' do 
        
        it 'should be of the form "Train between Haywards Heath and London Victoria"' do 
          route = routes(:victoria_to_haywards_heath)
          route.name(stops(:gatwick_airport_station)).should == 'Train between Haywards Heath and London Victoria'
        end
        
      end
      
      describe 'if the stop is a terminus' do 
        
        it 'should be of the form "Train to London Victoria"' do 
          route = routes(:victoria_to_haywards_heath)
          route.name(stops(:haywards_heath_station)).should == 'Train to London Victoria'
        end
        
      end

    end
  
  end
  
end
