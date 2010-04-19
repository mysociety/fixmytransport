# == Schema Information
# Schema version: 20100414172905
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

    fixtures :stops
    
    it 'should ignore case' do 
      Stop.find_by_atco_code('9100VICTric').should == stops(:victoria_station_one)
    end
    
  end
  
  describe 'when finding a common root area' do 

    fixtures :stops, :stop_areas, :stop_area_memberships, :stop_area_links
    
    it 'should return the common root stop area that all stops in the list belong to' do 
      stops = [stops(:victoria_station_one), stops(:victoria_station_two)]
      Stop.common_root_area(stops).should == stop_areas(:victoria_station_root)
    end
    
  end
  
  describe 'when finding stops from attributes' do 

    fixtures :stops, :stop_areas, :stop_area_memberships, :stop_area_links
    
    def expect_stop(attributes, stop)
      Stop.find_from_attributes(attributes).include?(stop).should be_true
    end
    
    it 'should not return stops with status "del"' do 
      deleted_stop = stops(:victoria_bus_station_deleted)
      attributes = { :common_name => 'victoria bus station', 
                     :locality_name => 'london', 
                     :stop_type_codes => ['BCT'] }
      Stop.find_from_attributes(attributes).include?(deleted_stop).should be_false
    end
    
    it 'should return stops that match the full common name, locality name and list of stop type codes' do     
      attributes = {:common_name => 'Bus Station Bay 16', 
                   :locality_name => 'Broadmead',
                   :stop_type_codes => ['BCT']} 
      expect_stop(attributes, stops(:bristol_16))
    end
      
    it 'should return stops that match a partial common name, locality name and list of stop type codes' do
      attributes = {:common_name => 'Bay 16', 
                   :locality_name => 'Broadmead',
                   :stop_type_codes => ['BCT']}
      expect_stop(attributes, stops(:bristol_16))
    end  
    
    it 'should return stops that match a full common name, locality name and list of stop type codes ignoring case ' do
      attributes = {:common_name => 'bUs station Bay 16', 
                    :locality_name => 'broadmead',
                    :stop_type_codes => ['BCT']} 
      expect_stop(attributes, stops(:bristol_16))
    end  
    
    it 'should return stops that match the full common name, parent locality name and list of stop type codes ignoring case' do 
      attributes = {:common_name => 'bUs station Bay 16', 
                    :locality_name => 'bristol',
                    :stop_type_codes => ['BCT']}
      expect_stop(attributes, stops(:bristol_16))
    end
    
    it 'should return a stops that match the full common name, grandparent locality name and list of stop type codes ignoring case' do
      attributes = {:common_name => 'dursley road', 
                    :locality_name => 'bristol',
                    :stop_type_codes => ['BCT']}
      expect_stop(attributes, stops(:dursley_road))
    end
    
  end
  
end

