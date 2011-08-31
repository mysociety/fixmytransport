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
        Gazetteer.bus_route_from_route_number('C10',
                                              'ZZ9 9ZZ',
                                              10,
                                              ignore_area=false,
                                              area_type=nil)[:error].should == :postcode_not_found
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

    describe 'when there is no error but no coordinates either' do

      before do
        MySociety::MaPit.stub!(:call).and_return(:areas => [], :postcode => 'ZZ9 9ZZ')
      end

      it 'should return a hash of postcode information with an error key' do
        Gazetteer.place_from_name('ZZ9 9ZZ').should == { :postcode_info => { :error => :area_not_known } }
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
        Locality.stub!(:find_all_by_full_name).and_return([@mock_locality])
      end

      it 'should return the localities in a hash with the key :localities' do
        Gazetteer.place_from_name('London').should == { :localities => [@mock_locality] }
      end

    end

    describe 'when no localities, but a district and some locations match the name' do

      before do
        @mock_district = mock_model(District)
        Locality.stub!(:find_all_by_full_name).and_return([])
        District.stub!(:find_all_by_full_name).and_return([@mock_district])
        @mock_stop = mock_model(Stop)
        Stop.stub!(:find).and_return([@mock_stop])
        StopArea.stub!(:find).and_return([])
      end

      describe 'when the mode has been set as :browse' do

        it 'should return the district in a hash with the key :district' do
          Gazetteer.place_from_name('London', nil, :browse).should == { :district => @mock_district }
        end

      end

      describe 'when the mode has been set as :find' do

        it 'should return the locations' do
          Gazetteer.place_from_name('London', nil, :find).should == { :locations => [@mock_stop] }
        end

      end

    end

    describe 'when one locality matches the name and a stop name has been passed' do

      before do
        mock_locality = mock_model(Locality)
        Locality.stub!(:find_all_by_full_name).and_return([mock_locality])
      end

      it 'should look for stops and stations in that locality matching the stop name' do
        Stop.should_receive(:find).and_return([])
        Gazetteer.should_receive(:find_stations_from_name).and_return([])
        Gazetteer.place_from_name('London', 'Camden Road')
      end

    end

    describe 'when no localities, but some stops or stations match the name' do

      before do
        Locality.stub!(:find_all_by_full_name).and_return([])
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
        Locality.stub!(:find_all_by_full_name).and_return([])
        Stop.stub!(:find).and_return([])
        StopArea.stub!(:find).and_return([])
      end

      it 'should return an empty hash' do
        Gazetteer.place_from_name('London').should == {}
      end

    end

  end

  describe 'when normalizing station names' do

    it 'should strip off the word "station" at the end of the search phrase' do
      Gazetteer.normalize_station_name('Euston station').should == 'Euston'
    end

    it 'should strip off the phrase "train station" at the end of the search phrase' do
      Gazetteer.normalize_station_name('Euston Train Station').should == 'Euston'
    end

    it 'should strip off the phrase "railway station" at the end of the search phrase' do
      Gazetteer.normalize_station_name('Euston railway station').should == 'Euston'
    end

    it 'should strip off the phrase "rail station" at the end of the search phrase' do
      Gazetteer.normalize_station_name('Euston rail station').should == 'Euston'
    end
  end

end