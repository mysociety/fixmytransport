# == Schema Information
# Schema version: 20100506162135
#
# Table name: transport_mode_stop_area_types
#
#  id                :integer         not null, primary key
#  transport_mode_id :integer
#  stop_area_type_id :integer
#  created_at        :datetime
#  updated_at        :datetime
#

require 'spec_helper'

describe TransportModeStopAreaType do
  before(:each) do
    @valid_attributes = {
      :transport_mode_id => 1,
      :stop_area_type_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    TransportModeStopAreaType.create!(@valid_attributes)
  end
end
