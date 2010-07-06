require 'spec_helper'

describe Admin::StopsController do

  describe 'GET #autocomplete_for_name' do 
    
    it 'should return stops identified by name' do 
      get :autocomplete_for_name, { :term => 'tennis' }
      results = JSON.parse(response.body)
      results.first['name'].should match(/Tennis Street/)
      results.second['name'].should match(/Tennis Court Inn/)
    end

    it 'should return stops filtered by transport mode id' do 
      get :autocomplete_for_name, { :term => 'victoria', :transport_mode_id => "1" }
      results = JSON.parse(response.body)
      results.first['name'].should match(/Victoria/)
      results.size.should == 1
    end
    
    it 'should return stops unfiltered by transport mode id if none is specified' do 
      get :autocomplete_for_name, { :term => 'victoria', :transport_mode_id => "" }
      results = JSON.parse(response.body)
      results.first['name'].should match(/Victoria/)
      results.size.should == 3
    end
    
  end
  
end