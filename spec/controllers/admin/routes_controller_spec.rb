require 'spec_helper'

describe Admin::RoutesController do

  describe 'GET #index' do 
  
    it 'should ask for all routes, ordered by number, paginated by default' do 
      Route.should_receive(:paginate).with(:page => nil, 
                                           :select=>"distinct routes.*",
                                           :conditions => [''], 
                                           :order => 'number asc', 
                                           :include => :region)
      get :index
    end
    
    it 'should ask for routes with part of the name or the whole number or operator code matching the query param' do 
      Route.should_receive(:paginate).with(:page => nil, 
                                           :select=>"distinct routes.*",
                                           :conditions => ['(lower(routes.name) like ? OR lower(number) = ?)',
                                                           '%%something%%', 'something'],
                                           :order => 'number asc', 
                                           :include => :region)
      get :index, :query => 'Something'
    end
    
    it 'should ask for routes with part of the name or the whole number or the id matching the query param if it is numeric' do
      Route.should_receive(:paginate).with(:page => nil, 
                                           :select=>"distinct routes.*",
                                           :conditions => ['(lower(routes.name) like ? OR lower(number) = ? OR routes.id = ?)',
                                                            '%%34%%', '34', 34],
                                            :order => 'number asc', 
                                            :include => :region)
      get :index, :query => '34'
    end
    
    it 'should ask for routes with the transport modes passed' do 
      Route.should_receive(:paginate).with(:page => nil, 
                                           :select=>"distinct routes.*",
                                           :conditions => ['transport_mode_id = ?',
                                                            '1'],
                                            :order => 'number asc', 
                                            :include => :region)
      get :index, :mode => '1'
    end
    
    
    it 'should ask for routes matching both the transport mode and query params' do 
      query_string = 'transport_mode_id = ? AND (lower(routes.name) like ? OR lower(number) = ?)'
      Route.should_receive(:paginate).with(:page => nil, 
                                           :select=>"distinct routes.*",
                                           :conditions => [query_string,
                                                           '1', '%%something%%', 'something'],
                                            :order => 'number asc',
                                            :include => :region)
      get :index, :mode => '1', :query => 'something'
    end
    
    it 'should ask for routes by page' do 
      Route.should_receive(:paginate).with(:page => '3', 
                                           :select=>"distinct routes.*",
                                           :conditions => [''], 
                                           :order => 'number asc',
                                           :include => :region)
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
      TransportMode.stub!(:find).and_return(mock_model(TransportMode, :name => 'Train', 
                                                                      :route_type => 'TrainRoute'))
      @route = mock_model(Route, :id => 400, :save => true, :status= => nil)
      Route.stub!(:new).and_return(@route)
      TrainRoute.stub!(:new).and_return(@route)
    end

    describe 'if no data is posted' do 
    
      it 'should render the "new" template' do 
        post :create, {}
        response.should render_template("new")
      end
    
    end

    it 'should create a new route with the route params' do 
      TrainRoute.should_receive(:new).with('name' => 'a new route', 'transport_mode_id' => '6').and_return(@route)
      post :create, { :route => { :name => 'a new route', :transport_mode_id => '6' } }
    end

    it 'should redirect to the admin route URL if the route can be saved' do 
      post :create, { :route => { :name => 'a new route', :transport_mode_id => '6'} }
      response.should redirect_to(controller.admin_url(admin_route_path(@route.id)))
    end
    
    it 'should render the template "new" if the route cannot be saved' do 
      @route.stub!(:save).and_return(false)
      post :create, { :route => { :name => 'a new route'} }
      response.should render_template('new')
    end
    
  end
  
  describe "DELETE #destroy" do 
 
    describe 'when the route has no campaigns or problems' do 
      
      before do 
        @route = mock_model(Route, :campaigns => [], :problems => [])
        Route.stub!(:find).and_return(@route)
      end
      
      it 'should destroy the route' do 
        @route.should_receive(:destroy)
        delete :destroy, :id => 33
      end
  
    end
    
    describe 'when the route has campaigns' do 
      
      before do 
        @route_source_admin_area = mock_model(RouteSourceAdminArea, :operator_code => 'TEST')
        @route = mock_model(Route, :campaigns => [mock_model(Campaign)], 
                                   :route_source_admin_areas => [@route_source_admin_area], 
                                   :id => 33)
        Route.stub!(:find).and_return(@route)
      end
      
      it 'should not destroy the route' do 
        @route.should_not_receive(:destroy)
        delete :destroy, :id => 33
      end

    end
 
    describe 'when the route has problems' do 
      
      before do 
        @route_source_admin_area = mock_model(RouteSourceAdminArea, :operator_code => 'TEST')
        @route = mock_model(Route, :campaigns => [], 
                                   :problems => [mock_model(Campaign)],
                                   :route_source_admin_areas => [@route_source_admin_area], 
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