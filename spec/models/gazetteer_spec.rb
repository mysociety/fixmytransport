require 'spec_helper'

describe Gazetteer do

  describe 'when finding routes from attributes' do 
    
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
    
    it 'should find a route that matches a name and passes within a km of a postcode if one is given' do 
      MySociety::MaPit.stub!(:get_location).with('SE1 4PF').and_return({"wgs84_lon" => -0.091322256961134, 
                                                                        "easting" => "532578", 
                                                                        "coordsyst" => "G", 
                                                                        "wgs84_lat" => 51.5012344990976, 
                                                                        "northing" => "179760"})
      attributes = { :transport_mode_id => 1, 
                     :route_number => '', 
                     :area => 'SE1 4PF' }
      routes = Gazetteer.find_routes_from_attributes(attributes)
      routes.should include(routes(:borough_C10))
      routes.size.should == 1
    end
    
  end
  
  describe 'when finding stops from attributes' do 

     def expect_stop(attributes, stop)
       Gazetteer.find_stops_from_attributes(attributes).include?(stop).should be_true
     end
     
     def expect_no_stop(attributes, stop)
       Gazetteer.find_stops_from_attributes(attributes).include?(stop).should_not be_true
     end

     before do 
       StopType.stub!(:codes_for_transport_mode).with(1).and_return(['BCT'])
       MySociety::MaPit.stub!(:get_location).with('SE1 4PF').and_return({"wgs84_lon" => -0.091322256961134, 
                                                                         "easting" => "532578", 
                                                                         "coordsyst" => "G", 
                                                                         "wgs84_lat" => 51.5012344990976, 
                                                                         "northing" => "179760"})
       
     end

     it 'should return stops that match the full common name, locality name and list of stop type codes' do     
       attributes = { :name => 'Bus Station Bay 16', 
                      :area => 'Broadmead',
                      :transport_mode_id => 1 } 
       expect_stop(attributes, stops(:bristol_16))
     end

     it 'should return stops that match a partial common name, locality name and list of stop type codes' do
       attributes = { :name => 'Bay 16', 
                      :area => 'Broadmead',
                      :transport_mode_id => 1 }
       expect_stop(attributes, stops(:bristol_16))
     end  

     it 'should return stops that match a full common name, locality name and list of stop type codes ignoring case ' do
       attributes = { :name => 'bUs station Bay 16', 
                      :area => 'broadmead',
                      :transport_mode_id => 1 } 
       expect_stop(attributes, stops(:bristol_16))
     end  

     it 'should return stops that match the full common name, parent locality name and list of stop type codes ignoring case' do 
       attributes = { :name => 'bUs station Bay 16', 
                      :area => 'bristol',
                      :transport_mode_id => 1 }
       expect_stop(attributes, stops(:bristol_16))
     end

     it 'should return a stops that match the full common name, grandparent locality name and list of stop type codes ignoring case' do
       attributes = { :name => 'dursley road', 
                      :area => 'bristol',
                      :transport_mode_id => 1 }
       expect_stop(attributes, stops(:dursley_road))
     end

     it 'should return stops matching a name within a mile of a postcode' do 
        attributes = { :name => 'Tennis', 
                       :area => 'SE1 4PF', 
                       :transport_mode_id => 1 }
        expect_stop(attributes, stops(:tennis_street))
     end
   
     it 'should not return stops within a mile of a postcode but not matching the name if a name is given' do 
       attributes = { :name => 'Tennis', 
                      :area => 'SE1 4PF', 
                      :transport_mode_id => 1 }
       expect_no_stop(attributes, stops(:borough_station))
     end
     
    it 'should not return stops matching a name but not within a mile of the postcode if a postcode is given' do 
      attributes = { :name => 'Tennis', 
                     :area => 'SE1 4PF', 
                     :transport_mode_id => 1 }
      expect_no_stop(attributes, stops(:tennis_court_inn))
    end
   
    it 'should return stops matching a name, route and area' do 
      attributes = { :name => 'Tennis', 
                     :area => 'SE1 4PF',
                     :route_number => 'C10', 
                     :transport_mode_id => 1 }
      expect_stop(attributes, stops(:tennis_street))
    end
    
   end
  

end