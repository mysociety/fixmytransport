# == Schema Information
# Schema version: 20100707152350
#
# Table name: stop_area_types
#
#  id          :integer         not null, primary key
#  code        :string(255)
#  description :text
#  created_at  :datetime
#  updated_at  :datetime
#

require 'spec_helper'

describe StopAreaType do
  before(:each) do
    @valid_attributes = {
      :code => "value for code",
      :description => "value for description"
    }
  end

  it "should create a new instance given valid attributes" do
    StopAreaType.create!(@valid_attributes)
  end
end
