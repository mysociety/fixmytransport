require 'spec_helper'

describe Admin::RoutesController do

  describe 'GET #index' do 
  
    it 'should ask for all routes, ordered by number, paginated by default' do 
      Route.should_receive(:paginate).with(:page => nil, 
                                           :select=>"distinct routes.*",
                                           :conditions => [''], 
                                           :order => 'number')
      get :index
    end
    
    it 'should ask for routes with part of the name or the whole number matching the query param' do 
      Route.should_receive(:paginate).with(:page => nil, 
                                           :select=>"distinct routes.*",
                                           :conditions => ['(lower(name) like ? OR lower(number) = ?)',
                                                           '%%something%%', 'something'],
                                           :order => 'number')
      get :index, :query => 'Something'
    end
    
    it 'should ask for routes with part of the name or the whole number or the id matching the query param if it is numeric' do
      Route.should_receive(:paginate).with(:page => nil, 
                                           :select=>"distinct routes.*",
                                           :conditions => ['(lower(name) like ? OR lower(number) = ? OR id = ?)',
                                                            '%%34%%', '34', 34],
                                            :order => 'number')
      get :index, :query => '34'
    end
    
    it 'should ask for routes with the transport modes passed' do 
      Route.should_receive(:paginate).with(:page => nil, 
                                           :select=>"distinct routes.*",
                                           :conditions => ['transport_mode_id = ?',
                                                            '1'],
                                            :order => 'number')
      get :index, :mode => '1'
    end
    
    
    it 'should ask for routes matching both the transport mode and query params' do 
      query_string = 'transport_mode_id = ? AND (lower(name) like ? OR lower(number) = ?)'
      Route.should_receive(:paginate).with(:page => nil, 
                                           :select=>"distinct routes.*",
                                           :conditions => [query_string,
                                                           '1', '%%something%%', 'something'],
                                            :order => 'number')
      get :index, :mode => '1', :query => 'something'
    end
    
    it 'should ask for routes by page' do 
      Route.should_receive(:paginate).with(:page => '3', 
                                           :select=>"distinct routes.*",
                                           :conditions => [''], 
                                           :order => 'number')
      get :index, :page => '3'
    end
  
  end
  
  describe "GET #new" do 
  
    it 'should create a new route' do 
      Route.should_receive(:new)
      get :new
    end
    
    it 'should create an empty list of route operators' do 
      get :new
      assigns[:route_operators].should == []
    end
    
  end

  describe "POST #create" do 
    
    before do 
      @route = mock_model(Route, :id => 400, :save => true)
      Route.stub!(:new).and_return(@route)
    end

    it 'should create a new route with the route params' do 
      Route.should_receive(:new).with('name' => 'a new route').and_return(@route)
      post :create, { :route => { :name => 'a new route' } }
    end

    it 'should redirect to the admin route URL if the route can be saved' do 
      post :create, { :route => { :name => 'a new route'} }
      response.should redirect_to(controller.admin_url(admin_route_path(@route.id)))
    end
    
    it 'should render the template "new" if the route cannot be saved' do 
      @route.stub!(:save).and_return(false)
      post :create, { :route => { :name => 'a new route'} }
      response.should render_template('new')
    end
    
  end
  
  describe "DELETE #destroy" do 
 
    describe 'when the route has no campaigns' do 
      
      before do 
        @route = mock_model(Route, :campaigns => [])
        Route.stub!(:find).and_return(@route)
      end
      
      it 'should destroy the route' do 
        @route.should_receive(:destroy)
        delete :destroy, :id => 33
      end
  
    end
    
    describe 'when the route has campaigns' do 
      
      before do 
        @route = mock_model(Route, :campaigns => [mock_model(Campaign)], 
                                   :operator_code => 'TEST', 
                                   :id => 33)
        Route.stub!(:find).and_return(@route)
      end
      
      it 'should not destroy the route' do 
        @route.should_not_receive(:destroy)
        delete :destroy, :id => 33
      end

    end
 
  end

end