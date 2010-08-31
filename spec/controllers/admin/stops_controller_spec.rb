require 'spec_helper'

describe Admin::StopsController do

  describe 'GET #index' do 
  
    it 'should ask for all stops, ordered by common name, paginated by default' do 
      Stop.should_receive(:paginate).with(:page => nil, 
                                           :conditions => [], 
                                           :order => 'common_name')
      get :index
    end
    
    it 'should ask for stops with part of the common name or street matching the query param' do 
      query_string = '(LOWER(common_name) LIKE ? OR LOWER(common_name) LIKE ? OR LOWER(street) LIKE ? OR LOWER(street) LIKE ?)'
      Stop.should_receive(:paginate).with(:page => nil, 
                                          :conditions => [query_string, 
                                          "something%", "%something%", "something%", "%something%"],
                                          :order => 'common_name')
      get :index, :query => 'Something'
    end
    
    it 'should ask for stops with part of the common name or street or the id matching the query param if it is numeric' do
      query_string = '(LOWER(common_name) LIKE ? OR LOWER(common_name) LIKE ? OR LOWER(street) LIKE ? OR LOWER(street) LIKE ? OR id = ?)'
      Stop.should_receive(:paginate).with(:page => nil, 
                                           :conditions => [query_string, 
                                            "34%", "%34%", "34%", "%34%", 34],
                                            :order => 'common_name')
      get :index, :query => '34'
    end
    
    it 'should ask for stops with the codes for the transport modes passed' do 
      Stop.should_receive(:paginate).with(:page => nil, 
                                          :conditions => ["stop_type in (?)", 
                                          ["BCQ", "BCT", "BCS", "BST", "BCE"]],
                                          :order => 'common_name')
      get :index, :mode => '1'
    end
    
    
    it 'should ask for stops matching both the transport mode and query params' do 
      query_string = '(LOWER(common_name) LIKE ? OR LOWER(common_name) LIKE ? OR LOWER(street) LIKE ? OR LOWER(street) LIKE ?) AND stop_type in (?)'
      Stop.should_receive(:paginate).with(:page => nil, 
                                           :conditions => [query_string,
                                           "something%", "%something%", "something%", "%something%", ["BCQ", "BCT", "BCS", "BST", "BCE"]],
                                            :order => 'common_name')
      get :index, :mode => '1', :query => 'something'
    end
    
    it 'should ask for routes by page' do 
      Stop.should_receive(:paginate).with(:page => '3', 
                                           :conditions => [], 
                                           :order => 'common_name')
      get :index, :page => '3'
    end
  
  end
  

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