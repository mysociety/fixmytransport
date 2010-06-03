require 'spec_helper'

describe Gazetteer do

  describe 'when finding routes by attributes' do 
    
    it 'should find any routes matching the number and transport mode id' do 
      attributes = { :transport_mode_id => 6, 
                     :route_number => '1F50', 
                     :area => '' }
      routes = Gazetteer.find_routes_from_attributes(attributes)
      routes.should include(routes(:victoria_to_haywards_heath))
    end
  
    it 'should find any routes matching the number and transport mode id disregarding case' do 
      attributes = { :transport_mode_id => 6, 
                     :route_number => '1f50', 
                     :area => '' }
      routes = Gazetteer.find_routes_from_attributes(attributes)
      routes.should include(routes(:victoria_to_haywards_heath))
    end
  
    it 'should find a route that can be uniquely identified by number and area' do 
      attributes = { :transport_mode_id => 1, 
                     :route_number => '807', 
                     :area => 'aldershot' }
      routes = Gazetteer.find_routes_from_attributes(attributes)
      routes.should include(routes(:aldershot_807_bus))
      routes.size.should == 1
    end
    
  end
  
  describe 'when finding stops from attributes' do 

     def expect_stop(attributes, stop)
       Gazetteer.find_stops_from_attributes(attributes).include?(stop).should be_true
     end

     before do 
       StopType.stub!(:codes_for_transport_mode).with(5).and_return(['BCT'])
     end

     it 'should return stops that match the full common name, locality name and list of stop type codes' do     
       attributes = { :name => 'Bus Station Bay 16', 
                      :area => 'Broadmead',
                      :transport_mode_id => 5 } 
       expect_stop(attributes, stops(:bristol_16))
     end

     it 'should return stops that match a partial common name, locality name and list of stop type codes' do
       attributes = { :name => 'Bay 16', 
                      :area => 'Broadmead',
                      :transport_mode_id => 5 }
       expect_stop(attributes, stops(:bristol_16))
     end  

     it 'should return stops that match a full common name, locality name and list of stop type codes ignoring case ' do
       attributes = { :name => 'bUs station Bay 16', 
                      :area => 'broadmead',
                      :transport_mode_id => 5 } 
       expect_stop(attributes, stops(:bristol_16))
     end  

     it 'should return stops that match the full common name, parent locality name and list of stop type codes ignoring case' do 
       attributes = { :name => 'bUs station Bay 16', 
                      :area => 'bristol',
                      :transport_mode_id => 5 }
       expect_stop(attributes, stops(:bristol_16))
     end

     it 'should return a stops that match the full common name, grandparent locality name and list of stop type codes ignoring case' do
       attributes = { :name => 'dursley road', 
                      :area => 'bristol',
                      :transport_mode_id => 5 }
       expect_stop(attributes, stops(:dursley_road))
     end

   end
  

end