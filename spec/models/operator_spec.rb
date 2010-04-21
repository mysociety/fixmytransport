# == Schema Information
# Schema version: 20100420165342
#
# Table name: operators
#
#  id         :integer         not null, primary key
#  code       :string(255)
#  name       :text
#  created_at :datetime
#  updated_at :datetime
#  short_name :string(255)
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
    Operator.create!(@valid_attributes)
  end
end
