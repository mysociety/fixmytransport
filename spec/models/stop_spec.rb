# == Schema Information
# Schema version: 20100707152350
#
# Table name: stops
#
#  id                       :integer         not null, primary key
#  atco_code                :string(255)
#  naptan_code              :string(255)
#  plate_code               :string(255)
#  common_name              :text
#  short_common_name        :text
#  landmark                 :text
#  street                   :text
#  crossing                 :text
#  indicator                :text
#  bearing                  :string(255)
#  town                     :string(255)
#  suburb                   :string(255)
#  locality_centre          :boolean
#  grid_type                :string(255)
#  easting                  :float
#  northing                 :float
#  lon                      :float
#  lat                      :float
#  stop_type                :string(255)
#  bus_stop_type            :string(255)
#  administrative_area_code :string(255)
#  creation_datetime        :datetime
#  modification_datetime    :datetime
#  revision_number          :integer
#  modification             :string(255)
#  status                   :string(255)
#  created_at               :datetime
#  updated_at               :datetime
#  coords                   :geometry
#  locality_id              :integer
#  cached_slug              :string(255)
#  loaded                   :boolean
#

require 'spec_helper'

describe Stop do
  
  before do 
    MySociety::MaPit.stub!(:call)
  end
  
  describe 'when creating' do 

    before(:each) do
       @valid_attributes = {
         :atco_code => "value for atco_code",
         :naptan_code => "value for naptan_code",
         :plate_code => "value for plate_code",
         :common_name => "value for common_name",
         :short_common_name => "value for short_common_name",
         :landmark => "value for landmark",
         :street => "value for street",
         :crossing => "value for crossing",
         :indicator => "value for indicator",
         :bearing => "value for bearing",
         :town => "value for town",
         :suburb => "value for suburb",
         :locality_centre => false,
         :grid_type => "value for grid_type",
         :easting => 1.5,
         :northing => 1.5,
         :lon => 1.5,
         :lat => 1.5,
         :stop_type => "value for stop_type",
         :bus_stop_type => "value for bus_stop_type",
         :administrative_area_code => "value for administrative_area_code",
         :creation_datetime => Time.now,
         :modification_datetime => Time.now,
         :revision_number => 1,
         :modification => "value for modification",
         :status => "value for status"
       }
     end
   
     it "should create a new instance given valid attributes" do
       Stop.create!(@valid_attributes)
     end
  
  end
  
  describe 'when finding by ATCO code' do 

    fixtures default_fixtures

    it 'should ignore case' do 
      Stop.find_by_atco_code('9100VICTric').should == stops(:victoria_station_one)
    end
    
  end
  
  describe 'when finding by name and coordinates' do 

    fixtures default_fixtures
    
    it 'should only return a stop whose name matches and whose coordinates are less than the specified distance away from the given stop' do 
      stop = Stop.find_by_name_and_coords('Haywards Heath Rail Station', 533030, 124583, 10)  
      stop.should == stops(:haywards_heath_station_interchange)
      stop = Stop.find_by_name_and_coords('Haywards Heath Rail Station', 533030, 124594, 10)  
      stop.should be_nil
    end
    
  end
  
  describe 'when finding a common area' do 

    fixtures default_fixtures
    
    it 'should return a common root stop area that all stops in the list belong to' do 
      stops = [stops(:victoria_station_one), stops(:victoria_station_two)]
      Stop.common_area(stops, 6).should == stop_areas(:victoria_station_root)
    end
    
    it 'should not return a stop area that not all stops in the list belong to' do 
       stops = [stops(:gatwick_airport_station), stops(:victoria_station_one)]
       Stop.common_area(stops, 6).should_not == stop_areas(:victoria_station_root)
    end
    
  end
  
  describe 'when giving a root stop area' do 

    fixtures default_fixtures
    
    it 'should return the parent stop area if there are more than one' do 
      stops(:victoria_station_one).root_stop_area('GRLS').should == stop_areas(:victoria_station_root)
      stops(:victoria_station_two).root_stop_area('GRLS').should == stop_areas(:victoria_station_root)
    end
    
  end
  
  describe 'when giving name without suffix' do 
    
    before do 
      @train_mode = mock_model(TransportMode, :name => 'Train')
      @tram_mode = mock_model(TransportMode, :name => 'Tram/Metro')
    end
    
    it 'should remove "Rail Station" from the end of a train station name' do 
      Stop.new(:common_name => "Kensington Rail Station").name_without_suffix(@train_mode).should == "Kensington"
    end
    
    it 'should remove "Underground Station" from the end of the name' do 
      Stop.new(:common_name => "Kensington Underground Station").name_without_suffix(@tram_mode).should == "Kensington"
    end
    
  end
  
  describe 'when asked for councils' do 
  
    before do 
      @stop = Stop.new(:lat => 100.1, :lon => 200.2)
      MySociety::MaPit.stub!(:call).and_return({ "33" => 
                                                 { "id" =>  "33", 
                                                   "name" => "A test area" } })
    end
    
    it 'should send a request to MaPit' do 
      council_types = ["DIS", "LBO", "MTD", "UTA", "LGD", "CTY", "COI"]
      MySociety::MaPit.should_receive(:call).with('point', '4326/200.2,100.1', :type => council_types)
      @stop.councils
    end
    
    it 'should create an array of council models from the returned data' do 
      councils = @stop.councils
      councils.is_a?(Array).should be_true
      councils.size.should == 1
      councils.first.class.to_s.should == 'Council'
      councils.first.name.should == "A test area"
    end
    
    it 'should set the councils as emailable if contact details are held for them' do 
      CouncilContact.stub!(:find_all_by_area_id).and_return([mock_model(CouncilContact)])
      @stop.councils.first.emailable?.should be_true
    end
    
    it 'should set the councils as not emailable if contact details are not held for them' do 
      CouncilContact.stub!(:find_all_by_area_id).and_return([])
      @stop.councils.first.emailable?.should be_false
    end

  end
  
  describe 'when asked for responsible organizations' do 
  
    it 'should return the operators if the only transport mode is train' do 
      mock_operator = mock_model(Operator)
      stop = Stop.new
      stop.stub!(:transport_mode_names).and_return(['Train'])
      stop.stub!(:operators).and_return([mock_operator])
      stop.responsible_organizations.should == [mock_operator]
    end
    
    describe 'when the transport mode is not train' do 
      
      it 'should return the PTE if there is one' do 
        mock_pte = mock_model(PassengerTransportExecutive)
        stop = Stop.new
        stop.stub!(:transport_mode_names).and_return(['Bus', 'Coach'])
        stop.stub!(:passenger_transport_executive).and_return(mock_pte)
        stop.responsible_organizations.should == [mock_pte]
      end
      
      it 'should return the councils if there is no PTE' do 
        mock_council = mock_model(Council)
        stop = Stop.new
        stop.stub!(:transport_mode_names).and_return(['Bus', 'Coach'])
        stop.stub!(:passenger_transport_executive).and_return(nil)
        stop.stub!(:councils).and_return([mock_council])
        stop.responsible_organizations.should == [mock_council]
      end
      
    end
  end
  
  describe 'as a transport location' do 
    
    before do 
      @instance = Stop.new
    end
    
    it_should_behave_like 'a transport location' 
  
  end
  
  describe 'when asked for a PTE' do 
    
    it 'should return one if there is one that covers one of the relevant councils' do
      mock_pte = mock_model(PassengerTransportExecutive)
      mock_pte_area = mock_model(PassengerTransportExecutiveArea, :pte => mock_pte)
      PassengerTransportExecutiveArea.stub!(:find_by_area_id).with(33).and_return(mock_pte_area)
      stop = Stop.new
      stop.stub!(:councils).and_return([mock('Council', :id => 33)])
      stop.passenger_transport_executive.should == mock_pte
    end
  
  end
  
  describe 'when asked for council info' do 
  
    it 'should create a pipe-delimited string of two comma delimited strings of emailable and not emailable council ids' do 
      stop = Stop.new
      stop.stub!(:emailable_councils).and_return([mock('Council', :id => 44)])
      stop.stub!(:unemailable_councils).and_return([])
      stop.council_info.should == '44|'
      stop.stub!(:emailable_councils).and_return([mock('Council', :id => 44), mock('Council', :id => 33)])
      stop.stub!(:unemailable_councils).and_return([mock('Council', :id => 55)])
      stop.council_info.should == '44,33|55'
    end
    
  end
  
end

