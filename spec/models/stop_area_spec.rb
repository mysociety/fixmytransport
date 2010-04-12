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
end
