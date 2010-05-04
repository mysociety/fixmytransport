# == Schema Information
# Schema version: 20100420165342
#
# Table name: stops
#
#  id                         :integer         not null, primary key
#  atco_code                  :string(255)
#  naptan_code                :string(255)
#  plate_code                 :string(255)
#  common_name                :text
#  short_common_name          :text
#  landmark                   :text
#  street                     :text
#  crossing                   :text
#  indicator                  :text
#  bearing                    :string(255)
#  nptg_locality_code         :string(255)
#  locality_name              :string(255)
#  parent_locality_name       :string(255)
#  grand_parent_locality_name :string(255)
#  town                       :string(255)
#  suburb                     :string(255)
#  locality_centre            :boolean
#  grid_type                  :string(255)
#  easting                    :float
#  northing                   :float
#  lon                        :float
#  lat                        :float
#  stop_type                  :string(255)
#  bus_stop_type              :string(255)
#  administrative_area_code   :string(255)
#  creation_datetime          :datetime
#  modification_datetime      :datetime
#  revision_number            :integer
#  modification               :string(255)
#  status                     :string(255)
#  created_at                 :datetime
#  updated_at                 :datetime
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
       :nptg_locality_code => "value for nptg_locality_code",
       :locality_name => "value for locality_name",
       :parent_locality_name => "value for parent_locality_name",
       :grand_parent_locality_name => "value for grand_parent_locality_name",
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
      Stop.common_area(stops).should == stop_areas(:victoria_station_root)
    end
    
  end
  
  describe 'when finding stops from attributes' do 
    
    def expect_stop(attributes, stop)
      Stop.find_from_attributes(attributes).include?(stop).should be_true
    end
    
    before do 
      StopType.stub!(:codes_for_transport_mode).with(5).and_return(['BCT'])
    end
    
    it 'should not return stops with status "del"' do 
      deleted_stop = stops(:victoria_bus_station_deleted)
      attributes = { :name => 'victoria bus station', 
                     :area => 'london', 
                     :transport_mode_id => 5 }
      Stop.find_from_attributes(attributes).include?(deleted_stop).should be_false
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
  
  describe 'when giving name without station' do 
  
    it 'should remove "Rail Station" from the end of the name' do 
      Stop.new(:common_name => "Kensington Rail Station").name_without_station.should == "Kensington"
    end
    
  end
  
  describe 'when giving name without metro station' do 
  
    it 'should remove "Underground Station" from the end of the name' do 
      Stop.new(:common_name => "Kensington Underground Station").name_without_metro_station.should == "Kensington"
    end
    
  end
  
end

