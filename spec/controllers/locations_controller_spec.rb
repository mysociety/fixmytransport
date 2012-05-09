require 'spec_helper'

describe LocationsController do


  describe 'GET #show_stop_area' do

    before do
      @model_type = StopArea
      @default_params = { :type => :stop_area, :scope => 'london', :id => 'euston' }
      @scope_model = Locality
      @scope_field = :locality
    end

    it_should_behave_like "a show action that falls back to a previous generation and redirects"

    def make_request(params=@default_params)
      get :show_stop_area, params
    end

    it 'should redirect to a station url if the stop area is a train station' do
      mock_stop_area = mock_model(StopArea, :area_type => 'GRLS',
                                            :locality => 'london',
                                            :station_root => nil)
      StopArea.stub!(:full_find).and_return(mock_stop_area)
      make_request
      response.should redirect_to(station_url(mock_stop_area.locality, mock_stop_area))
    end

    it 'should redirect to a station url if the stop area is a metro station' do
      mock_stop_area = mock_model(StopArea, :area_type => 'GTMU',
                                            :locality => 'london',
                                            :station_root => nil)
      StopArea.stub!(:full_find).and_return(mock_stop_area)
      make_request
      response.should redirect_to(station_url(mock_stop_area.locality, mock_stop_area))
    end

    it 'should redirect to a ferry terminal url if the stop area is a ferry terminal' do
      mock_stop_area = mock_model(StopArea, :area_type => 'GFTD',
                                            :locality => 'london',
                                            :station_root => nil)
      StopArea.stub!(:full_find).and_return(mock_stop_area)
      make_request
      response.should redirect_to(ferry_terminal_url(mock_stop_area.locality, mock_stop_area))
    end

    describe 'if there is an ancestor area of the same type' do

      before do
        @parent_stop_area = mock_model(StopArea, :area_type => 'GRLS',
                                                :ancestors => [],
                                                :locality => 'victoria')
        @mock_stop_area = mock_model(StopArea, :area_type => 'GRLS',
                                              :locality => 'victoria',
                                              :station_root => @parent_stop_area)
        StopArea.stub!(:full_find).and_return(@mock_stop_area)
      end

      it 'should redirect to the ancestor area if there is one of the same type' do
        make_request
        response.should redirect_to(station_url(@parent_stop_area.locality, @parent_stop_area))
      end

      it 'should have a response code of 301 (moved permanently)' do
        make_request
        response.status.should == '301 Moved Permanently'
      end


    end

    describe 'when request is directed at an asset server' do

      before do
        MySociety::Config.stub!(:get)
        MySociety::Config.stub!(:get).with("DOMAIN", 'assets.example.com').and_return("test.host")
        @request.host = "assets.example.com"
      end

      it 'should redirect to the main domain' do
        make_request
        response.should redirect_to('http://test.host/stop-areas/london/euston')
      end

      it 'should have a response code of 301 (moved permanently)' do
        make_request
        response.status.should == '301 Moved Permanently'
      end

    end

  end

  describe 'GET #show_route' do

    fixtures default_fixtures

    before do
      @route = routes(:victoria_to_haywards_heath)
      @model_type = Route
      @default_params = { :scope => 'london', :id => 'c10' }
      @includes = {:route_operators => :operator}
      @scope_model = Region
      @scope_field = :region
    end

    it_should_behave_like "a show action that falls back to a previous generation and redirects"

    def make_request(params=@default_params)
      get :show_route, params
    end

    it 'should not find a route by its id' do
      make_request({:id => @route.id, :scope => 'great-britain'})
      response.status.should == '404 Not Found'
    end

  end

  describe 'GET #add_comment_to_route' do

    before do
      @mock_route = mock_model(Route)
      Route.stub!(:find).and_return(@mock_route)
    end

    def make_request
      get :add_comment_to_route, {:id => 44, :scope => 66 }
    end

    it 'should look for the route' do
      Route.should_receive(:find).with("44", :scope => "66")
      make_request
    end

    it 'should render the template "add_comment"' do
      make_request
      response.should render_template('shared/add_comment')
    end

  end

  describe 'GET #show_stop' do

    before do
      @model_type = Stop
      @scope_model = Locality
      @scope_field = :locality
      @controller.stub!(:map_params_from_location)
      @default_params = { :id => "44", :scope => "66" }
      @stop = mock_model(Stop, :full_name => "A Test Stop",
                               :points => [])

    end

    it_should_behave_like "a show action that falls back to a previous generation and redirects"

    def make_request(params=@default_params)
      get :show_stop, params
    end

    it 'should render the "show_stop" template' do
      Stop.stub!(:full_find).and_return(@stop)
      make_request
      response.should render_template('locations/show_stop')
    end
  end

  describe 'GET #add_comment_to_stop' do

    before do
      @mock_stop = mock_model(Stop)
      Stop.stub!(:find).and_return(@mock_stop)
    end

    def make_request
      get :add_comment_to_stop, { :id => 44, :scope => 66 }
    end

    it 'should look for the stop' do
      Stop.should_receive(:find).with("44", :scope => "66")
      make_request
    end

    it 'should render the template "add_comment"' do
      make_request
      response.should render_template('shared/add_comment')
    end

  end

  describe 'GET #add_comment_to_stop_area' do

    before do
      @mock_stop_area = mock_model(StopArea)
      StopArea.stub!(:find).and_return(@mock_stop_area)
    end

    def make_request
      get :add_comment_to_stop_area, {:id => 44, :scope => 66 }
    end

    it 'should look for the stop' do
      StopArea.should_receive(:find).with("44", :scope => "66")
      make_request
    end

    it 'should render the template "add_comment"' do
      make_request
      response.should render_template('shared/add_comment')
    end

  end

  describe 'GET #add_comment_to_sub_route' do

    before do
      @mock_sub_route = mock_model(SubRoute)
      SubRoute.stub!(:find).and_return(@mock_sub_route)
    end

    def make_request
      get :add_comment_to_sub_route, { :id => 44 }
    end

    it 'should look for the sub route' do
      SubRoute.should_receive(:find).with("44")
      make_request
    end

    it 'should render the template "add_comment"' do
      make_request
      response.should render_template('shared/add_comment')
    end

  end

  def make_mock_comment(type, instance)
    comment = mock_model(Comment, :save => true,
                                  :valid? => true,
                                  :user= => true,
                                  :commented_id => 22,
                                  :commented_type => type,
                                  :commented => instance,
                                  :text => 'comment text',
                                  :confirm! => true,
                                  :mark_fixed => nil,
                                  :mark_open => nil,
                                  :skip_name_validation= => true,
                                  :user_marks_as_fixed? => false,
                                  :needs_questionnaire? => false,
                                  :status= => true)
    instance.stub!(:comments).and_return(mock('comments', :build => comment))
    comment
  end

  describe 'POST #add_comment_to_route' do

    before do
      @mock_user = mock_model(User)
      @mock_region = mock_model(Region)
      @mock_model = mock_model(Route, :region => @mock_region)
      Route.stub!(:find).and_return(@mock_model)
      @expected_notice = "Please sign in or create an account to add your comment to this route"
    end

    def make_request params
      post :add_comment_to_route, params
    end

    def default_params
      { :id => 22,
        :scope => 43,
        :comment => { :commentable_id => 55,
                      :commentable_type => 'Route'} }
    end

    it_should_behave_like "an action that receives a POSTed comment"

  end


  describe 'POST #add_comment_to_stop' do

    before do
      @mock_user = mock_model(User)
      @mock_locality = mock_model(Locality)
      @mock_model = mock_model(Stop, :locality => @mock_locality)
      Stop.stub!(:find).and_return(@mock_model)
      @expected_notice = "Please sign in or create an account to add your comment to this stop"
    end

    def make_request params
      post :add_comment_to_stop, params
    end

    def default_params
      { :id => 22,
        :scope => 43,
        :comment => { :commentable_id => 55,
                      :commentable_type => 'Stop'} }
    end

    it_should_behave_like "an action that receives a POSTed comment"

  end

  describe 'POST #add_comment_to_stop_area' do

    before do
      @mock_user = mock_model(User)
      @mock_locality = mock_model(Locality)
      @mock_model = mock_model(StopArea, :locality => @mock_locality, :area_type => 'GRLS')
      StopArea.stub!(:find).and_return(@mock_model)
      @expected_notice = "Please sign in or create an account to add your comment to this station"
    end

    def make_request params
      post :add_comment_to_stop_area, params
    end

    def default_params
      { :id => 22,
        :scope => 43,
        :comment => { :commentable_id => 55,
                      :commentable_type => 'StopArea'} }
    end

    it_should_behave_like "an action that receives a POSTed comment"

  end


  describe 'POST #add_comment_to_sub_route' do

    before do
      @mock_user = mock_model(User)
      @mock_model = mock_model(SubRoute)
      SubRoute.stub!(:find).and_return(@mock_model)
      @expected_notice = "Please sign in or create an account to add your comment to this route"
    end

    def make_request params
      post :add_comment_to_sub_route, params
    end

    def default_params
      { :id => 22,
        :comment => { :commentable_id => 55,
                      :commentable_type => 'SubRoute'} }
    end

    it_should_behave_like "an action that receives a POSTed comment"

  end
end