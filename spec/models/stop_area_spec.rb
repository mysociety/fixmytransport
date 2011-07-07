# == Schema Information
# Schema version: 20100707152350
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
#  locality_id              :integer
#  loaded                   :boolean
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
    stop_area = StopArea.new(@valid_attributes)
    stop_area.valid?.should be_true
  end
  
  describe 'when loading' do 
    
    before do 
      @stop_area = StopArea.new(@valid_attributes)
      @stop_area.loaded = false
    end
    
    it 'should not require locality' do 
      @stop_area.locality_id = nil
      @stop_area.valid?.should be_true
    end
    
  end
  
  describe 'when loaded' do 
  
    before do 
      @stop_area = StopArea.new(@valid_attributes)
      @stop_area.loaded = true
    end
  
  end
  
  describe ' area ' do 
    
    fixtures default_fixtures
  
    describe 'for stop areas whose stops all share a locality' do
      
      it 'should return the locality_name' do 
        stop_areas(:victoria_station_leaf).area.should == "Victoria"
      end
    
    end
    
    describe 'for areas whose stops do not share a locality' do 
      
      it 'should return nil' do 
        stop_areas(:victoria_station_root).area.should be_nil
      end
      
    end
    
  end
  
  describe ' description ' do
    
    describe 'for stop areas with an area attribute' do 
  
      before do
        @stop_area = StopArea.new(:name => 'London Victoria Rail Station')
        @stop_area.stub!(:area).and_return('Victoria')
      end
    
      it 'should be of the form "name in area" ' do 
        @stop_area.description.should == "London Victoria Rail Station in Victoria"
      end
    
    end
  
  end 
  
  describe 'as a transport location' do 
    
    before do 
      @instance = StopArea.new
    end
    
    it_should_behave_like 'a transport location' 
  
  end

  describe 'when mapping a list of stop areas to common areas' do 
    
    fixtures default_fixtures
    
    it 'should return a list that does not include any member of the original list whose ancestor is also in the list' do 
      stop_list = [stop_areas(:victoria_station_leaf), stop_areas(:victoria_station_root)]
      StopArea.map_to_common_areas(stop_list).should == [stop_areas(:victoria_station_root)]
    end
  
  end
end
