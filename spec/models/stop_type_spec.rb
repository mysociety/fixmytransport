# == Schema Information
# Schema version: 20100707152350
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
#  sub_type    :string(255)
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
  
  describe 'when giving conditions for transport modes' do 
    
    it 'should return conditions specifying a set of stop types for buses' do 
      StopType.conditions_for_transport_mode(1).should == ['stop_type in (?)', [["BCQ", "BCT", "BCS", "BST", "BCE"]]]
    end
  
    it 'should return conditions specifying stop type "BCT" and metro_stop being true for tram/metro stops' do 
      StopType.conditions_for_transport_mode(7).should == ["stop_type in (?) and metro_stop = ?", [["BCT"], true]]
    end
  
  end
  
end
