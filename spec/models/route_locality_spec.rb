# == Schema Information
# Schema version: 20100707152350
#
# Table name: route_localities
#
#  id          :integer         not null, primary key
#  locality_id :integer
#  route_id    :integer
#  created_at  :datetime
#  updated_at  :datetime
#

require 'spec_helper'

describe RouteLocality do
  before(:each) do
    @valid_attributes = {
      :locality_id => 1,
      :route_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    RouteLocality.create!(@valid_attributes)
  end
end
