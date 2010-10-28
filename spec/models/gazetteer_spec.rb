require 'spec_helper'

describe Gazetteer do

  def stub_postcode_finder
    @coords = { "wgs84_lon" => -0.091, 
               "easting" => "532578", 
               "coordsyst" => "G", 
               "wgs84_lat" => 51.50, 
               "northing" => "179760" }
    MySociety::MaPit.stub!(:call).and_return(@coords)
  end
  
  describe 'when finding a route from a route number and area' do 
  
    before do 
      stub_postcode_finder
    end
    
    describe 'when the postcode finder returns an error' do 
    
      before do 
        MySociety::MaPit.stub!(:call).and_return(:not_found)        
      end
      
      it 'should return the error :postcode_not_found in the results hash' do 
        Gazetteer.bus_route_from_route_number('C10', 'ZZ9 9ZZ', 10)[:error].should == :postcode_not_found
      end
      
    end
  
    describe 'if given a partial postcode' do 
    
      it 'should look for localities within 5km of the partial postcode centroid' do 
        Locality.should_receive(:find_by_coordinates).with("532578", "179760", 5000).and_return([])
        Gazetteer.bus_route_from_route_number('C10', 'ZZ9', 10)
      end
      
    end
    
    describe 'if given a full postcode' do 
    
      it 'should look for localities within 1km of the postcode point' do
        Locality.should_receive(:find_by_coordinates).with("532578", "179760", 1000).and_return([])
        Gazetteer.bus_route_from_route_number('C10', 'ZZ9 9ZZ', 10)
      end
      
    end
    
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
  
  
end