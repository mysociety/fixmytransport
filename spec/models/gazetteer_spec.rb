require 'spec_helper'

describe Gazetteer do

  describe 'when finding routes by attributes' do 
    
    it 'should find any routes matching the number and transport mode id' do 
      attributes = { :transport_mode_id => 6, 
                     :route_number => '1F50', 
                     :area => '' }
      routes = Gazetteer.find_routes_from_attributes(attributes)
      routes.should include(routes(:victoria_to_haywards_heath))
    end
  
    it 'should find any routes matching the number and transport mode id disregarding case' do 
      attributes = { :transport_mode_id => 6, 
                     :route_number => '1f50', 
                     :area => '' }
      routes = Gazetteer.find_routes_from_attributes(attributes)
      routes.should include(routes(:victoria_to_haywards_heath))
    end
  
    it 'should find a route that can be uniquely identified by number and area' do 
      attributes = { :transport_mode_id => 1, 
                     :route_number => '807', 
                     :area => 'aldershot' }
      routes = Gazetteer.find_routes_from_attributes(attributes)
      routes.should include(routes(:aldershot_807_bus))
      routes.size.should == 1
    end
    
  end

end