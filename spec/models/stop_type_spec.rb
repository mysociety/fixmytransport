# == Schema Information
# Schema version: 20100506162135
#
# Table name: stop_types
#
#  id          :integer         not null, primary key
#  code        :string(255)
#  description :string(255)
#  on_street   :boolean
#  point_type  :string(255)
#  version     :float
#  created_at  :datetime
#  updated_at  :datetime
#

require 'spec_helper'

describe StopType do
  before(:each) do
    @valid_attributes = {
      :code => "value for code",
      :description => "value for description",
      :on_street => false,
      :point_type => "value for point_type",
      :version => 1.5
    }
  end

  it "should create a new instance given valid attributes" do
    stop_type = StopType.new(@valid_attributes)
    stop_type.valid?.should be_true
  end
  
  
end
