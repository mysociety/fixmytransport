# == Schema Information
# Schema version: 20100414172905
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
end
