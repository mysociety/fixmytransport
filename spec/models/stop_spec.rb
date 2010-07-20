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
  
  describe 'when finding by ATCO code' do 

    it 'should ignore case' do 
      Stop.find_by_atco_code('9100VICTric').should == stops(:victoria_station_one)
    end
    
  end
  
  describe 'when finding by name and coordinates' do 
    
    it 'should only return a stop whose name matches and whose coordinates are less than the specified distance away from the given stop' do 
      stop = Stop.find_by_name_and_coords('Haywards Heath Rail Station', 533030, 124583, 10)  
      stop.should == stops(:haywards_heath_station)
      stop = Stop.find_by_name_and_coords('Haywards Heath Rail Station', 533030, 124594, 10)  
      stop.should be_nil
    end
    
  end
  
  describe 'when finding a common area' do 
    
    it 'should return a common root stop area that all stops in the list belong to' do 
      stops = [stops(:victoria_station_one), stops(:victoria_station_two)]
      Stop.common_area(stops, 6).should == stop_areas(:victoria_station_root)
    end
    
    it 'should not return a stop area that not all stops in the list belong to' do 
       stops = [stops(:gatwick_airport_station), stops(:victoria_station_one)]
       Stop.common_area(stops, 6).should_not == stop_areas(:victoria_station_root)
    end
    
  end
  
  describe 'when giving name without suffix' do 
  
    it 'should remove "Rail Station" from the end of a train station name' do 
      Stop.new(:common_name => "Kensington Rail Station").name_without_suffix(transport_modes(:train)).should == "Kensington"
    end
    
    it 'should remove "Underground Station" from the end of the name' do 
      Stop.new(:common_name => "Kensington Underground Station").name_without_suffix(transport_modes(:tram_metro)).should == "Kensington"
    end
    
  end
  
end

