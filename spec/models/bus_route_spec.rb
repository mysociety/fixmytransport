# == Schema Information
# Schema version: 20100506162135
#
# Table name: routes
#
#  id                :integer         not null, primary key
#  transport_mode_id :integer
#  number            :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  type              :string(255)
#

require 'spec_helper'
require 'route_spec_helper'

describe BusRoute do
  
  describe 'when finding existing routes' do 
  
    it 'should include in the results returned a route with the same number, mode of transport and stop codes' do 
      atco_codes = ['13001288E', '13001612B', '13001612B']
      route = BusRoute.new(:number => '807', 
                           :transport_mode_id => 1)
      add_stops_from_list route, atco_codes
      BusRoute.find_existing(route).include?(routes(:number_807_bus)).should be_true
    end
    
  end
  
  describe 'name' do 
  
    it 'should be of the form "Bus route 807"' do 
      route = routes(:number_807_bus)
      route.name.should == 'Bus route 807'
    end
  
  end
  
  
end
