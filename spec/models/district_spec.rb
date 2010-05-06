require 'spec_helper'

describe District do
  before(:each) do
    @valid_attributes = {
      :code => "value for code",
      :name => "value for name",
      :admin_area_id => 1,
      :creation_datetime => Time.now,
      :modification_datetime => Time.now,
      :revision_number => "value for revision_number",
      :modification => "value for modification"
    }
  end

  it "should create a new instance given valid attributes" do
    District.create!(@valid_attributes)
  end
end
