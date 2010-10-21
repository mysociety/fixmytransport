require 'spec_helper'

describe Gazetteer do

  def stub_postcode_finder
    coords = { "wgs84_lon" => -0.091, 
               "easting" => "532578", 
               "coordsyst" => "G", 
               "wgs84_lat" => 51.50, 
               "northing" => "179760" }
    MySociety::MaPit.stub!(:call).and_return(coords)
  end
  
  describe 'when finding a place from a name' do 
    
    before do 
      stub_postcode_finder
    end
    
    describe 'when the postcode finder returns an error' do
    
      before do 
        MySociety::MaPit.stub!(:call).and_return(:not_found)        
      end
      
      it 'should return a hash of postcode information with an error key' do 
        Gazetteer.place_from_name('ZZ9 9ZZ').should == { :postcode_info => { :error => :not_found } }
      end
      
    end
      
    describe "when the name is a full postcode" do
      
      describe 'when the postcode finder returns coordinate info' do 
        
        it 'should return a hash of postcode information with coordinate info' do 
          Gazetteer.place_from_name('ZZ9 9ZZ')[:postcode_info][:lat].should == 51.50
          Gazetteer.place_from_name('ZZ9 9ZZ')[:postcode_info][:lon].should == -0.091      
        end
        
        it 'should return a zoom level of the max. visible zoom level' do
          Gazetteer.place_from_name('ZZ9 9ZZ')[:postcode_info][:zoom].should == MAX_VISIBLE_ZOOM
        end
        
      end
      
      describe 'when the name is a partial postcode' do 
      
        it 'should return a zoom level of one less than the max. visible zoom level' do 
          Gazetteer.place_from_name('ZZ9')[:postcode_info][:zoom].should == MAX_VISIBLE_ZOOM - 1
        end
      
      end
    
    end
    
    describe 'when localities match the name' do 
      
      before do 
        @mock_locality = mock_model(Locality)
        Locality.stub!(:find_all_by_lower_name).and_return([@mock_locality])
      end
      
      it 'should return the localities in a hash with the key :localities' do 
        Gazetteer.place_from_name('London').should == {:localities => [@mock_locality]}
      end
      
    end
    
    describe 'when no localities, but some stops or stations match the name' do
      
      before do 
        Locality.stub!(:find_all_by_lower_name).and_return([])
        @mock_stop = mock_model(Stop)
        Stop.stub!(:find).and_return([@mock_stop])
        StopArea.stub!(:find).and_return([])
      end
      
      it 'should return the stops and stations in a hash with the key :locations' do 
        Gazetteer.place_from_name('London').should == {:locations => [@mock_stop]}
      end
    
    end
    
    describe 'when nothing matches the name' do 
      
      before do 
        Locality.stub!(:find_all_by_lower_name).and_return([])
        Stop.stub!(:find).and_return([])
        StopArea.stub!(:find).and_return([])
      end
      
      it 'should return an empty hash' do 
        Gazetteer.place_from_name('London').should == {}
      end
    
    end
    
  end
  
  describe 'when finding routes from attributes' do 
    
    it 'should find any routes matching the number and transport mode id' do 
      attributes = { :transport_mode_id => 6, 
                     :route_number => '1F50', 
                     :area => '' }
      results = Gazetteer.find_routes_from_attributes(attributes)
      results[:results].should include(routes(:victoria_to_haywards_heath))
    end
      
    it 'should find any routes matching the number and transport mode id disregarding case' do 
      attributes = { :transport_mode_id => 6, 
                     :route_number => '1f50', 
                     :area => '' }
      results = Gazetteer.find_routes_from_attributes(attributes)
      results[:results].should include(routes(:victoria_to_haywards_heath))
    end
      
    it 'should find a route that can be uniquely identified by number and area' do 
      attributes = { :transport_mode_id => 1, 
                     :route_number => '807', 
                     :area => 'aldershot' }
      results = Gazetteer.find_routes_from_attributes(attributes)
      results[:results].should include(routes(:aldershot_807_bus))
      results[:results].size.should == 1
    end
    
    it 'should find a route that matches a name and passes within a km of a postcode if one is given' do 
      stub_postcode_finder
      attributes = { :transport_mode_id => 1, 
                     :route_number => '', 
                     :area => 'SE1 4PF' }
      results = Gazetteer.find_routes_from_attributes(attributes)
      results[:results].should include(routes(:borough_C10))
      results[:results].size.should == 1
    end
    
    it 'should find a route given part of a route name' do 
      stub_postcode_finder
      attributes = { :transport_mode_id => 7, 
                     :route_number => 'metropolitan', 
                     :area => '' }
      results = Gazetteer.find_routes_from_attributes(attributes)
      results[:results].should include(routes(:metropolitan_line))
      results[:results].size.should == 1
    end
  end
  
  describe 'when finding stops from attributes' do 

     def expect_stop(attributes, stop)
       results = Gazetteer.find_stops_and_stations_from_attributes(attributes)
       results[:results].include?(stop).should be_true
     end
     
     def expect_no_stop(attributes, stop)
       results = Gazetteer.find_stops_and_stations_from_attributes(attributes)
       results[:results].include?(stop).should_not be_true
     end

     before do 
       stub_postcode_finder
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
    
    it 'should not return stops if the area is given but not recognized' do 
      attributes = { :name => 'Tennis', 
                     :area => 'Unrecognizable',
                     :route_number => 'C10', 
                     :transport_mode_id => 1 }
      Gazetteer.find_stops_and_stations_from_attributes(attributes)[:results].size.should == 0
    end
    
    it 'should return an error if the area is given but not recognized' do 
      attributes = { :name => 'Tennis', 
                     :area => 'Unrecognizable',
                     :route_number => 'C10', 
                     :transport_mode_id => 1 }
      Gazetteer.find_stops_and_stations_from_attributes(attributes)[:errors].should == [:area_not_found]
    end
    
    it 'should not return stops if the postcode is given but not found' do 
      MySociety::MaPit.stub!(:call).and_return(:not_found)
      attributes = { :name => 'Tennis',
                     :area => 'SE2 4PF',
                     :route_number => 'C10', 
                     :transport_mode_id => 1 }
      Gazetteer.find_stops_and_stations_from_attributes(attributes)[:results].size.should == 0
    end
    
    it 'should return an error if the postcode is given but not recognized' do 
      MySociety::MaPit.stub!(:call).and_return(:bad_request)
      attributes = { :name => 'Tennis', 
                     :area => 'SE2 4PF',
                     :route_number => 'C10', 
                     :transport_mode_id => 1 }
      Gazetteer.find_stops_and_stations_from_attributes(attributes)[:errors].should == [:postcode_not_found]
    end
    
    it 'should return a stop area if that stop area is the common root parent of all stops matching the attributes' do 
      attributes = { :name => 'Victoria', 
                     :area => 'London',
                     :transport_mode_id => 6 }
      Gazetteer.find_stops_and_stations_from_attributes(attributes)[:results].should == [stop_areas(:victoria_station_root)]
    end
    
  end

end