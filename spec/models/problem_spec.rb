# == Schema Information
# Schema version: 20100408151525
#
# Table name: problems
#
#  id          :integer         not null, primary key
#  subject     :text
#  description :text
#  created_at  :datetime
#  updated_at  :datetime
#  reporter_id :integer
#  stop_id     :integer
#

require 'spec_helper'

describe Problem do
  before(:each) do
    @valid_attributes = {
      :subject => "value for subject",
      :description => "value for description"
    }
  end

  it "should create a new instance given valid attributes" do
    Problem.create!(@valid_attributes)
  end
end
