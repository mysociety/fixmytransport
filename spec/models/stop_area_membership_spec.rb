# == Schema Information
# Schema version: 20100707152350
#
# Table name: stop_area_memberships
#
#  id                    :integer         not null, primary key
#  stop_id               :integer
#  stop_area_id          :integer
#  creation_datetime     :datetime
#  modification_datetime :datetime
#  revision_number       :integer
#  modification          :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#

require 'spec_helper'

describe StopAreaMembership do
  before(:each) do
    @valid_attributes = {
      :stop_id => 1,
      :stop_area_id => 1,
      :creation_datetime => Time.now,
      :modification_datetime => Time.now,
      :revision_number => 1,
      :modification => "value for modification"
    }
    @default_attrs = {}
    @model_type = StopAreaMembership
  end

  it_should_behave_like "a model that exists in data generations"

  it_should_behave_like "a model that exists in data generations and is versioned"

  it "should create a new instance given valid attributes" do
    membership = StopAreaMembership.new(@valid_attributes)
    membership.valid?.should be_true
  end

  after(:each) do
    StopAreaMembership.destroy_all
  end

end
