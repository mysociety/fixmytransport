# == Schema Information
# Schema version: 20100707152350
#
# Table name: operators
#
#  id              :integer         not null, primary key
#  code            :string(255)
#  name            :text
#  created_at      :datetime
#  updated_at      :datetime
#  short_name      :string(255)
#  email           :text
#  email_confirmed :boolean
#  notes           :text
#

require 'spec_helper'

describe Operator do
  before(:each) do
    @valid_attributes = {
      :code => "value for code",
      :name => "value for name"
    }
  end

  it "should create a new instance given valid attributes" do
    operator = Operator.new(@valid_attributes)
    operator.valid?.should be_true
  end
  
  it 'should require the name attribute' do 
    operator = Operator.new(@valid_attributes)
    operator.name = nil
    operator.valid?.should be_false
  end
  
  it "should not create an associated route operator if the attributes passed don't contain an '_add' item" do
    @valid_attributes["route_operators_attributes"] = {"1" => { "_add" => "0", 
                                                                "route_id" => routes(:borough_C10).id } }
    operator = Operator.create(@valid_attributes) 
    operator.route_operators.size.should == 0
  end
  
  it "should create an associated route operator if the attributes passed contain an '_add' item whose value is 1" do 
    @valid_attributes["route_operators_attributes"] = { "1" => { "_add" => "1", 
                                                                 "route_id" => routes(:borough_C10).id } }
    operator = Operator.create(@valid_attributes) 
    operator.route_operators.size.should == 1
  end
  
end
