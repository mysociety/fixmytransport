# == Schema Information
# Schema version: 20100707152350
#
# Table name: districts
#
#  id                    :integer         not null, primary key
#  code                  :string(255)
#  name                  :text
#  admin_area_id         :integer
#  creation_datetime     :datetime
#  modification_datetime :datetime
#  revision_number       :string(255)
#  modification          :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#

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
