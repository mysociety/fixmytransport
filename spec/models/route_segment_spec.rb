# == Schema Information
# Schema version: 20100707152350
#
# Table name: route_segments
#
#  id            :integer         not null, primary key
#  from_stop_id  :integer
#  to_stop_id    :integer
#  from_terminus :boolean
#  to_terminus   :boolean
#  route_id      :integer
#  created_at    :datetime
#  updated_at    :datetime
#

require 'spec_helper'

describe RouteSegment do
  before(:each) do
    @valid_attributes = {
      :from_stop_id => 1,
      :to_stop_id => 1,
      :from_terminus => false,
      :to_terminus => false,
      :route_id => 1,
      :segment_order => 0
    }
    @model_type = RouteSegment
    @default_attrs = { :from_stop_id => 1,
                       :to_stop_id => 1,
                       :segment_order => 0 }
  end

  it "should create a new instance given valid attributes" do
    route_segment = RouteSegment.new(@valid_attributes)
    route_segment.valid?.should be_true
  end

  it_should_behave_like "a model that exists in data generations"

  it_should_behave_like "a model that exists in data generations and is versioned"

end
