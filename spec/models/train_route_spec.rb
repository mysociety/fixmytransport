# == Schema Information
# Schema version: 20100707152350
#
# Table name: routes
#
#  id                :integer         not null, primary key
#  transport_mode_id :integer
#  number            :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  type              :string(255)
#  name              :string(255)
#  region_id         :integer
#  cached_slug       :string(255)
#  operator_code     :string(255)
#  loaded            :boolean
#

require 'spec_helper'
require 'route_spec_helper'

describe TrainRoute do
  
  describe 'description' do
  
    it 'should be of the form "Train route between Haywards Heath and London Victoria"' do 
      route = routes(:victoria_to_haywards_heath)
      route.description.should == 'Train route between Haywards Heath and London Victoria'
    end
    
  end
  
  describe 'name' do 
  
    it 'should be of the form "Train route between Haywards Heath and London Victoria"' do 
      route = routes(:victoria_to_haywards_heath)
      route.name.should == 'Train route between Haywards Heath and London Victoria'
    end
    
    describe 'when given a stop to start from' do 
      
      describe 'if the stop is not a terminus' do 
        
        it 'should be of the form "Train between Haywards Heath and London Victoria"' do 
          route = routes(:victoria_to_haywards_heath)
          route.name(stops(:gatwick_airport_station)).should == 'Train between Haywards Heath and London Victoria'
        end
        
      end
      
      describe 'if the stop is a terminus' do 
        
        it 'should be of the form "Train to London Victoria"' do 
          route = routes(:victoria_to_haywards_heath)
          route.name(stops(:haywards_heath_station)).should == 'Train towards London Victoria'
        end
        
      end

    end
  
  end
  
end
