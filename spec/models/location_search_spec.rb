# == Schema Information
# Schema version: 20100707152350
#
# Table name: location_searches
#
#  id                :integer         not null, primary key
#  transport_mode_id :integer
#  name              :string(255)
#  area              :string(255)
#  route_number      :string(255)
#  location_type     :string(255)
#  session_id        :string(255)
#  events            :text
#  active            :boolean
#  created_at        :datetime
#  updated_at        :datetime
#

require 'spec_helper'

describe LocationSearch do
  before(:each) do
    @valid_attributes = {
      :transport_mode_id => 1,
      :name => "value for name",
      :area => "value for area",
      :route_number => "value for route_number",
      :location_type => "value for location_type"
    }
  end

  it "should create a new instance given valid attributes" do
    LocationSearch.create!(@valid_attributes)
  end


end
