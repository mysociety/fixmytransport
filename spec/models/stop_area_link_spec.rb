# == Schema Information
# Schema version: 20100414172905
#
# Table name: stop_area_links
#
#  id            :integer         not null, primary key
#  ancestor_id   :integer
#  descendant_id :integer
#  direct        :boolean
#  count         :integer
#  created_at    :datetime
#  updated_at    :datetime
#

require 'spec_helper'

describe StopAreaLink do
  before(:each) do
    @valid_attributes = {
      :ancestor_id => 1,
      :descendant_id => 2
    }
  end

  it "should create a new instance given valid attributes" do
    StopAreaLink.create!(@valid_attributes)
  end
end
