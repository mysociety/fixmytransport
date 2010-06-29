require 'spec_helper'

describe Admin::RoutesController do

  describe 'GET #index' do 
  
    it 'should ask for all routes, ordered by number, paginated by default' do 
      Route.should_receive(:paginate).with(:page => nil, 
                                           :conditions => [''], 
                                           :order => 'number')
      get :index
    end
    
    it 'should ask for routes with part of the name or the whole number matching the query param' do 
      Route.should_receive(:paginate).with(:page => nil, 
                                           :conditions => ['(lower(name) like ? OR lower(number) = ?)',
                                                           '%%something%%', 'something'],
                                           :order => 'number')
      get :index, :query => 'Something'
    end
    
    it 'should ask for routes with part of the name or the whole number or the id matching the query param if it is numeric' do
      Route.should_receive(:paginate).with(:page => nil, 
                                           :conditions => ['(lower(name) like ? OR lower(number) = ? OR id = ?)',
                                                            '%%34%%', '34', 34],
                                            :order => 'number')
      get :index, :query => '34'
    end
    
    it 'should ask for routes with the transport modes passed' do 
      Route.should_receive(:paginate).with(:page => nil, 
                                           :conditions => ['transport_mode_id = ?',
                                                            '1'],
                                            :order => 'number')
      get :index, :mode => '1'
    end
    
    
    it 'should ask for routes matching both the transport mode and query params' do 
      query_string = 'transport_mode_id = ? AND (lower(name) like ? OR lower(number) = ?)'
      Route.should_receive(:paginate).with(:page => nil, 
                                           :conditions => [query_string,
                                                           '1', '%%something%%', 'something'],
                                            :order => 'number')
      get :index, :mode => '1', :query => 'something'
    end
    
    it 'should ask for routes by page' do 
      Route.should_receive(:paginate).with(:page => '3', 
                                           :conditions => [''], 
                                           :order => 'number')
      get :index, :page => '3'
    end
  
  end

end