# == Schema Information
# Schema version: 20100408173847
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
end
