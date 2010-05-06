# == Schema Information
# Schema version: 20100506162135
#
# Table name: transport_modes
#
#  id          :integer         not null, primary key
#  name        :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#  naptan_name :string(255)
#  active      :boolean
#  route_type  :string(255)
#

require 'spec_helper'

describe TransportMode do
  before(:each) do
    @valid_attributes = {
      :name => "value for name"
    }
  end

  it "should create a new instance given valid attributes" do
    TransportMode.create!(@valid_attributes)
  end
end
