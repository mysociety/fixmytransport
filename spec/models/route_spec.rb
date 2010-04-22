# == Schema Information
# Schema version: 20100420102749
#
# Table name: routes
#
#  id                :integer         not null, primary key
#  transport_mode_id :integer
#  number            :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#

require 'spec_helper'

describe Route do
  before(:each) do
    @valid_attributes = {
      :transport_mode_id => 1,
      :number => "value for number"
    }
  end

  it "should create a new instance given valid attributes" do
    route = Route.new(@valid_attributes)
    route.valid?.should be_true
  end
  
  describe 'when finding existing routes' do 
    
    fixtures :stops, :routes, :route_stops, :transport_modes
  
    it 'should include in the results returned a route with the same number, mode of transport and stop codes' do 
      attributes = { :number => '1F50', 
                     :transport_mode_id => 5, 
                     :stop_codes => ['9100VICTRIC', '9100CLPHMJC', '9100ECROYDN', '9100GTWK', '9100HYWRDSH'] }
      Route.find_existing(attributes).include?(routes(:victoria_to_haywards_heath)).should be_true
    end
    
  end
  
end
