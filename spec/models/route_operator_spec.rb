# == Schema Information
# Schema version: 20100707152350
#
# Table name: route_operators
#
#  id          :integer         not null, primary key
#  operator_id :integer
#  route_id    :integer
#  created_at  :datetime
#  updated_at  :datetime
#

require 'spec_helper'

describe RouteOperator do
  before(:each) do
    @valid_attributes = {
      :operator_id => 1,
      :route_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    route_operator = RouteOperator.new(@valid_attributes)
    route_operator.valid?.should be_true
  end
end
