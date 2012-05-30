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
    @stop = Stop.new
    @stop.stub!(:persistent_id).and_return(44)
    @stop_area = StopArea.new
    @stop_area.stub!(:persistent_id).and_return(55)
    @default_attrs = { :stop => @stop, :stop_area => @stop_area }
    @model_type = StopAreaMembership
    @expected_identity_hash = { :stop => {:persistent_id => 44 },
                                :stop_area => {:persistent_id => 55 }}
    @expected_external_identity_fields = [{:stop=>[:atco_code, :name]}, {:stop_area=>[:code, :name]}]
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
