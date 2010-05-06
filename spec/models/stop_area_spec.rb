# == Schema Information
# Schema version: 20100506162135
#
# Table name: stop_areas
#
#  id                       :integer         not null, primary key
#  code                     :string(255)
#  name                     :text
#  administrative_area_code :string(255)
#  area_type                :string(255)
#  grid_type                :string(255)
#  easting                  :float
#  northing                 :float
#  creation_datetime        :datetime
#  modification_datetime    :datetime
#  revision_number          :integer
#  modification             :string(255)
#  status                   :string(255)
#  created_at               :datetime
#  updated_at               :datetime
#  coords                   :geometry
#  lon                      :float
#  lat                      :float
#

require 'spec_helper'

describe StopArea do
  before(:each) do
    @valid_attributes = {
      :code => "value for code",
      :name => "value for name",
      :administrative_area_code => "value for administrative_area_code",
      :area_type => "value for area_type",
      :grid_type => "value for grid_type",
      :easting => 1.5,
      :northing => 1.5,
      :creation_datetime => Time.now,
      :modification_datetime => Time.now,
      :revision_number => 1,
      :modification => "value for modification",
      :status => "value for status"
    }
  end

  it "should create a new instance given valid attributes" do
    StopArea.create!(@valid_attributes)
  end
  
  describe ' area ' do 
  
    describe 'for stop areas whose stops all share a locality_name' do
      
      it 'should return the locality_name' do 
        stop_areas(:victoria_station_leaf).area.should == "Victoria"
      end
    
    end
    
    describe 'for areas whose stops do not share a locality_name' do 
      
      it 'should return nil' do 
        stop_areas(:victoria_station_root).area.should be_nil
      end
      
    end
    
  end
  
  describe ' description ' do
    
    describe 'for stop areas with an area attribute' do 
  
      it 'should be of the form "name in area" ' do 
        stop_areas(:victoria_station_leaf).description.should == "London Victoria Rail Station in Victoria"
      end
    
    end
  
  end 

end
