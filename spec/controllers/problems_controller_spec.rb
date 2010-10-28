require 'spec_helper'

describe ProblemsController do

  describe 'GET #frontpage' do 
    
    def make_request
      get :frontpage 
    end  
    
  end
  
  describe "GET #find_train_route" do 
  
    def make_request(params={})
      get :find_train_route, params
    end
  
    before do 
      @mock_route = mock_model(Route, :region => mock_model(Region, :name => 'Great Britain'))
    end
    
    describe 'when the "to" or "from" param is present but empty' do 
    
      it 'should render the "find_train_route" template' do 
        make_request({:to => '', :from => ''})
        response.should render_template("find_train_route")
      end
      
      it 'should display an error message' do 
        make_request({:to => '', :from => ''})
        assigns[:error_message].should == 'Please enter the names of the stations where you got on and off the train.'
      end
      
    end
    
    describe 'when the "to" and "from" params are supplied' do
    
      it 'should ask the gazetteer for routes' do 
        Gazetteer.should_receive(:train_route_from_stations_and_time).and_return({:routes => []})
        make_request({:to => "london euston", :from => 'birmingham new street'})
      end
      
      describe 'when one route is returned' do 
      
        it 'should redirect to that route' do 
          Gazetteer.stub!(:train_route_from_stations_and_time).and_return(:routes => [@mock_route])
          make_request({:to => "london euston", :from => 'birmingham new street'})
          response.should redirect_to(route_url(@mock_route.region, @mock_route))
        end
        
      end
      
      describe 'when no routes are returned' do 
      
        it 'should display an error message' do 
          Gazetteer.stub!(:train_route_from_stations_and_time).and_return(:routes => [])
          make_request({:to => "london euston", :from => 'birmingham new street'})
          assigns[:error_message].should == 'We could not find the route you entered.'
        end
        
      end
    
      describe 'when multiple routes are returned' do 

        before do 
          Gazetteer.stub!(:train_route_from_stations_and_time).and_return(:routes => [@mock_route, @mock_route])
        end
        
        it 'should assign the routes to the template as locations' do 
          make_request({:to => "london euston", :from => 'birmingham new street'})
          assigns[:locations].should == [@mock_route, @mock_route]
        end
        
        it 'should render the template "choose train route"' do 
          make_request({:to => "london euston", :from => 'birmingham new street'})
          response.should render_template("choose_train_route")
        end
        
      end
      
    end
    
  end
  
  describe "GET #find_bus_route" do 
  
    def make_request(params={})
      get :find_bus_route, params
    end
    
    describe 'when a route_number parameter is not supplied' do 
  
      it 'should render the template "find_bus_route"' do 
        make_request
        response.should render_template('find_bus_route')
      end
  
    end
    
    describe 'when a route_number parameter is supplied' do 
      
      it 'should ask the gazetteer for up to ten routes from the route_number and area' do 
        Gazetteer.should_receive(:bus_route_from_route_number).with('C10', 'London', 10).and_return({ :routes => [] })
        make_request(:route_number => 'C10', :area => 'London')
      end
      
    end
    
    describe 'when the gazetteer finds multiple routes' do 
    
      before do 
        @mock_route = mock_model(Route, :show_as_point= => true, 
                                        :show_as_point => true,
                                        :lat => 51.1,
                                        :lon => 0.1)
        Gazetteer.stub!(:bus_route_from_route_number).and_return({ :routes => [@mock_route, @mock_route]})
      end
    
      it 'should show the choose route template' do 
        make_request(:route_number => 'C10', :area => 'London')
        response.should render_template("choose_route")
      end
      
      describe 'if there is an error' do 
      
        it 'should pass an appropriate error message to the template' do 
          Gazetteer.stub!(:bus_route_from_route_number).and_return( { :routes => [@mock_route, @mock_route], 
                                                                      :error => :postcode_not_found })
          make_request(:route_number => 'C10', :area => 'London')
          assigns[:error_message].should == "The postcode you entered wasn't recognized."
        end
      
      end
    
      it 'should set the "display as point" flag on each route' do
        @mock_route.should_receive(:show_as_point=).with(true).exactly(2).times
        make_request(:route_number => 'C10', :area => 'London')
      end
      
      it 'should set the map params from the routes' do 
        @controller.should_receive(:map_params_from_location).with([@mock_route, @mock_route], find_other_locations=false)
        make_request(:route_number => 'C10', :area => 'London')
      end
      
    end
    
  end
  
  describe "GET #find_stop" do 
  
    def make_request(params={})
      get :find_stop, params
    end
    
    describe 'when a name parameter is not supplied' do 
      
      it 'should render the template "find_stop"' do 
        make_request
        response.should render_template('find_stop')
      end
      
    end
    
    describe 'when a name parameter is supplied' do 
      
      it 'should ask the Gazetteer for a place from the name' do 
        Gazetteer.should_receive(:place_from_name).with('Euston').and_return({})
        make_request({:name => 'Euston'})
      end
      
      describe 'when localities are returned by the gazetteer' do 
                
        describe 'when there is only one locality returned' do 
        
          before do
            @mock_locality = mock_model(Locality, :lat => 51.1, :lon => 0.01)
            Gazetteer.stub!(:place_from_name).and_return({:localities => [@mock_locality]})
          end
            
          it 'should set map params based on the locality' do 
            @controller.should_receive(:map_params_from_location).with([@mock_locality], find_other_locations=true)
            make_request({:name => 'Euston'})
          end
        
          it 'should set the list of primary locations to display to empty' do 
            make_request({:name => 'Euston'})
            assigns[:locations].should == []
          end
    
          it 'should render the "choose_location" template' do 
            make_request({:name => 'Euston'})
            response.should render_template('problems/choose_location')
          end
        
        end
        
        describe 'when there is more than one locality returned' do 
          
          before do 
            @mock_locality = mock_model(Locality, :lat => 51.1, :lon => 0.01)
            Gazetteer.stub!(:place_from_name).and_return({:localities => [@mock_locality, @mock_locality]})
          end
          
          it 'should render the "choose_locality" template' do 
            make_request({:name => 'Euston'})
            response.should render_template('choose_locality')
          end
          
          it 'should assign the localities for the view' do 
            make_request({:name => 'Euston'})
            assigns[:localities].should == [@mock_locality, @mock_locality]
          end
        
        end
        
        describe 'when locations are returned by the gazetteer' do 
          
          before do 
            @mock_stop = mock_model(Stop, :lat => 51.1, :lon => 0.01)
            Gazetteer.stub!(:place_from_name).and_return({:locations => [@mock_stop]})
          end
          
          it 'should set the map params based on the locations' do 
            @controller.should_receive(:map_params_from_location).with([@mock_stop], find_other_locations=true)
            make_request({:name => 'Euston'})
          end
          
          it 'should set the list of primary locations to display to the locations' do 
            make_request({:name => 'Euston'})
            assigns[:locations].should == [@mock_stop]
          end
          
          it 'should render the "choose_location" template' do 
            make_request({:name => 'Euston'})
            response.should render_template('choose_location')
          end
          
        end
        
        describe 'when the gazeteer returns postcode information' do 
        
          describe 'when the postcode information includes an error' do 
         
            before do 
              Gazetteer.stub!(:place_from_name).and_return({:postcode_info => {:error => :bad_request }})
            end
            
            it 'should render the "find_stop" template' do 
              make_request({:name => 'ZZ9 9ZZ'})
              response.should render_template('find_stop')
            end
             
            it 'should display an appropriate error message' do 
              make_request({:name => 'ZZ9 9ZZ'})
              assigns[:error_message].should == "That postcode wasn't recognized."
            end

          end
          
          describe 'when the postcode information includes a lat value' do 
            
            before do 
              Gazetteer.stub!(:place_from_name).and_return({:postcode_info => {:lat => 51.1, 
                                                                               :lon => 0.10, 
                                                                               :zoom => 15}})
            end
            
            it 'should assign the lat, lon and zoom for the view based on the postcode info' do 
              make_request({:name => 'ZZ9 9ZZ'})
              assigns[:lat].should == 51.1
              assigns[:lon].should == 0.10
              assigns[:zoom].should == 15
            end
            
            it 'should assign the list of primary locations to display to empty' do 
              make_request({:name => 'ZZ9 9ZZ'})
              assigns[:locations].should == []              
            end
            
            it 'should set the other locations based on the lat lon and zoom for the postcode' do 
              mock_location = mock('location')
              Map.should_receive(:other_locations).with(51.1, 0.10, 15).and_return([mock_location])
              make_request({:name => 'ZZ9 9ZZ'})
              assigns[:other_locations].should == [mock_location]
            end
            
            it 'should ask the view to find other locations' do 
              make_request({:name => 'ZZ9 9ZZ'})
              assigns[:find_other_locations].should be_true
            end
            
            it 'should render the "choose_locations" template' do 
              make_request({:name => 'ZZ9 9ZZ'})
              response.should render_template("problems/choose_location")
            end
            
          end
        end
        
      end
      
    end

  end
  
  describe "POST #create" do 

    before do 
      @stop = stops(:victoria_station_one)
      @mock_user = mock_model(User)
      @mock_problem = mock_model(Problem, :valid? => true, 
                                          :save => true, 
                                          :save_reporter => true,
                                          :location => @stop,
                                          :reporter => @mock_user, 
                                          :create_assignments => true)
      Problem.stub!(:new).and_return(@mock_problem)
      @mock_assignment = mock_model(Assignment)
      Assignment.stub!(:create_assignments).and_return(@mock_assignment)
      @problem_attributes = { "location_id" => 55, "location_type" => 'Stop' }
    end
    
    def make_request(is_campaign=nil)
      post :create, { :problem => @problem_attributes, :is_campaign => is_campaign }
    end
    
    it 'should create a new problem using the attributes passed to it' do 
      Problem.should_receive(:new).with(@problem_attributes)
      make_request
    end
    
    it 'should try to save the problem if it is valid' do 
      @mock_problem.should_receive(:save)
      make_request
    end
    
    it 'should try to save the reporter if the problem is valid' do 
      @mock_problem.should_receive(:save_reporter)
      make_request
    end
    
    it 'should render the "new" template if the problem is not valid' do 
      @mock_problem.stub!(:valid?).and_return(false)
      make_request
      response.should render_template('problems/new')
    end
    
    it 'should render the "confirmation_sent" template if the problem can be saved' do 
      make_request
      response.should render_template('shared/confirmation_sent')
    end
    
    it 'should create assignments associated with the problem' do 
      @mock_problem.should_receive(:create_assignments).and_return(@mock_assignment)
      make_request
    end
    
    it 'should create a campaign with status "New" associated with the problem if passed the parameter "is_campaign"' do 
      @mock_problem.should_receive(:build_campaign).with({ :location_id => @problem_attributes["location_id"], 
                                                           :location_type => @problem_attributes["location_type"],
                                                           :status => :new, 
                                                           :initiator => @mock_user })
      make_request(is_campaign="1")
    end
    
  end
  
  describe "PUT #update" do 
  
    before do 
      @mock_problem = mock_model(Problem, :updates => [])
      @mock_update = mock_model(Update, :valid? => true, :save => true, :save_reporter => true)
      @mock_problem.updates.stub!(:build).and_return(@mock_update)
      Problem.stub!(:find).and_return(@mock_problem)
    end
    
    def make_request
      put :update, { :id => 55, 
                     :problem => { :title => 'a new title', 
                                   :updates => { :text => 'test' } } }
    end
    
    it 'should find the problem by id' do 
      Problem.should_receive(:find).with('55')
      make_request
    end
    
    it 'should only pass on parameters for a new update' do 
      @mock_problem.updates.should_receive(:build).with({ 'text' => 'test' })
      make_request
    end
    
    it 'should save the update it is valid' do 
      @mock_update.should_receive(:save)
      make_request
    end
    
    it 'should save the update reporter if the update is valid' do 
      @mock_update.should_receive(:save_reporter)
      make_request
    end
    
    it 'should render the "confirmation_sent" template if the update is valid' do 
      make_request
      response.should render_template('shared/confirmation_sent')
    end
    
  end
  
  describe "GET #confirm" do 
     
    before do 
      @mock_assignment = mock_model(Assignment)
      @mock_problem = mock_model(Problem, :update_attributes => true, 
                                          :assignments => [@mock_assignment],
                                          :emailable_organization_info => [],
                                          :emailable_organizations => [], 
                                          :campaign => nil)
      Problem.stub!(:find_by_token).and_return(@mock_problem)
      Assignment.stub!(:complete_problem_assignments)
    end

    def make_request
      get :confirm, { :email_token => "my-test-token" }
    end

    it 'should look for the problem by token' do 
      Problem.should_receive(:find_by_token).with("my-test-token")
      make_request
    end

    it 'should set the status to confirmed and set the confirmed time on the problem' do 
      @mock_problem.should_receive(:update_attributes).with(:status => :confirmed, :confirmed_at => anything)
      make_request
    end

    it 'should set the "publish-problem" assignments associated with this user and problem as complete' do 
      assignment_data =  { 'publish-problem' => {} }
      Assignment.should_receive(:complete_problem_assignments).with(@mock_problem, assignment_data)
      make_request
    end
    
    it 'should set the "write-to-transport-organization" assignment associated with this user and problem as complete if ' do 
      @mock_problem.stub!(:emailable_organizations).and_return([mock_model(Operator)])
      @mock_problem.stub!(:organization_info).and_return({ :data => 'data' })
      assignment_data ={ 'write-to-transport-organization' => { :organizations => {:data => 'data'} } }
      Assignment.should_receive(:complete_problem_assignments).with(@mock_problem, assignment_data)
      make_request
    end
    
    it 'should not get the "write-to-transport-organization" assignment associated with this user and problem as complete if there are no emailable organizations' do 
      @mock_problem.stub!(:emailable_organizations).and_return([])
      @mock_problem.stub!(:organization_info).and_return({ :data => 'data' })
      assignment_data ={ 'write-to-transport-organization' => { :data => 'data' } }
      Assignment.should_not_receive(:complete_problem_assignments).with(@mock_problem, hash_including({'write-to-transport-organization'=> { :data => 'data' } }))
      make_request
    end
    
    it 'should render the "confirm" view if there is no campaign associated with the problem' do 
      make_request
      response.should render_template("problems/confirm")
    end
    
    it 'should redirect to the campaign edit page passing the token if there is a campaign associated with the problem' do 
      @mock_campaign = mock_model(Campaign)
      @mock_problem.stub!(:campaign).and_return(@mock_campaign)
      make_request
      response.should redirect_to(edit_campaign_url(@mock_campaign, :token => 'my-test-token'))
    end

  end
  
  describe 'when setting up problem advice' do 
    
    before do 
      # set up the controller and template by making a request
      get :frontpage
    end
    
    def expect_advice(mock_problem, advice)
      controller.send(:setup_problem_advice, mock_problem).should == advice
    end
  
    it 'should generate advice text for a bus/coach stop covered by a PTE' do 
      mock_pte = mock_model(PassengerTransportExecutive, :emailable? => true, 
                                                         :name => 'test PTE')      
      mock_stop = mock_model(Stop, :transport_mode_names => ['Bus', 'Coach'])
      mock_problem = mock_model(Problem, :location => mock_stop,
                                         :responsible_organizations => [mock_pte])
      expected = ["Your problem will be sent to <strong>test PTE</strong>.", 
                  "The subject and details of your problem will be public."].join(' ')
      expect_advice(mock_problem, expected)
    end
    
    it 'should generate advice text for a bus/coach stop with multiple uncontactable councils' do 
      mock_council_one = mock_model(Council, :emailable? => false, :name => "Test Council One")
      mock_council_two = mock_model(Council, :emailable? => false, :name => "Test Council Two")      
      mock_stop = mock_model(Stop, :transport_mode_names => ['Bus', 'Coach'])
      mock_problem = mock_model(Problem, :location => mock_stop, 
                                         :responsible_organizations => [mock_council_one, mock_council_two])
      expected = ["We do not yet have contact details for <strong>Test Council One</strong>",
                  "or <strong>Test Council Two</strong>.  If you submit a problem here the",
                  "subject and description of the problem will be public, but it will",
                  "<strong>not</strong> be sent to them."].join(' ')
      expect_advice(mock_problem, expected)
    end
    
    it 'should generate advice text for a bus/coach stop with one uncontactable council' do 
      mock_council = mock_model(Council, :emailable? => false, :name => "Test Council")
      mock_stop = mock_model(Stop, :transport_mode_names => ['Bus', 'Coach'])
      mock_problem = mock_model(Problem, :location => mock_stop, 
                                         :responsible_organizations => [mock_council])
      expected = ["We do not yet have contact details for <strong>Test Council</strong>.",
                  "If you submit a problem here the subject and description of the problem",
                  "will be public, but it will <strong>not</strong> be sent to Test",
                  "Council."].join(' ')
      expect_advice(mock_problem, expected)
    end
    
    it 'should generate advice text for a bus/coach stop with one contactable council' do 
      mock_council = mock_model(Council, :emailable? => true, :name => "Test Council")
      mock_stop = mock_model(Stop, :transport_mode_names => ['Bus', 'Coach'])
      mock_problem = mock_model(Problem, :location => mock_stop, 
                                         :responsible_organizations => [mock_council])
      expected = ["Your problem will be sent to <strong>Test Council</strong>.",
                  "The subject and details of your problem will be public."].join(' ')
      expect_advice(mock_problem, expected)
    end
    
    it 'should generate advice text for a bus/coach stop with multiple contactable councils' do 
      mock_council_one = mock_model(Council, :emailable? => true, :name => "Test Council One")
      mock_council_two = mock_model(Council, :emailable? => true, :name => "Test Council Two")  
      mock_stop = mock_model(Stop, :transport_mode_names => ['Bus', 'Coach'])
      mock_problem = mock_model(Problem, :location => mock_stop, 
                                         :responsible_organizations => [mock_council_one, mock_council_two],
                                         :operators_responsible? => false)
      expected = ["Your problem will be sent to <strong>Test Council One</strong> or",
                  "<strong>Test Council Two</strong>. The subject and details of your", 
                  "problem will be public."].join(' ')
      expect_advice(mock_problem, expected)
    end
    
    it 'should generate advice text for a bus/coach stop with multiple councils, some contactable' do 
      mock_council_one = mock_model(Council, :emailable? => false, :name => "Test Council One")
      mock_council_two = mock_model(Council, :emailable? => true, :name => "Test Council Two")  
      mock_stop = mock_model(Stop, :transport_mode_names => ['Bus', 'Coach'])
      mock_problem = mock_model(Problem, :location => mock_stop,
                                         :responsible_organizations => [mock_council_one, mock_council_two],
                                         :emailable_organizations => [mock_council_two], 
                                         :unemailable_organizations => [mock_council_one],
                                         :operators_responsible? => false, 
                                         :councils_responsible? => true)
      expected = ["Your problem will be sent to <strong>Test Council One</strong> or <strong>Test",
                  "Council Two</strong>. The subject and description of the problem will be public."].join(' ')
      expect_advice(mock_problem, expected)
    end
    
    it 'should generate advice text for a bus/coach stop with no responsible organization' do 
      mock_stop = mock_model(Stop, :transport_mode_names => ['Bus', 'Coach'])
      mock_problem = mock_model(Problem, :location => mock_stop, 
                                         :responsible_organizations => [])
      expected = ["We do not yet know who is responsible for this stop. If you submit a problem",
                  "here the subject and description of the problem will be public, but it will",
                  "<strong>not</strong> be sent to them."].join(' ')
      expect_advice(mock_problem, expected)
    end
    
    it 'should generate advice text for a bus route with no operators' do
      mock_route = mock_model(Route, :transport_mode_names => ['Bus'])
      mock_problem = mock_model(Problem, :location => mock_route, 
                                         :responsible_organizations => [])
      expected = ["We do not yet know who is responsible for this route. If you submit a problem",
                  "here the subject and description of the problem will be public, but it will",
                  "<strong>not</strong> be sent to them."].join(' ')
      expect_advice(mock_problem, expected)
    end
    
    it 'should generate advice text for a bus route with multiple operators, some emailable' do 
      mock_operator_one = mock_model(Operator, :name => 'Test Operator One', :emailable? => true)
      mock_operator_two = mock_model(Operator, :name => 'Test Operator Two', :emailable? => false)
      mock_route = mock_model(Route, :transport_mode_names => ['Bus'])
      mock_problem = mock_model(Problem, :location => mock_route, 
                                         :responsible_organizations => [mock_operator_one, mock_operator_two],
                                         :emailable_organizations => [mock_operator_one],
                                         :unemailable_organizations => [mock_operator_two],
                                         :operators_responsible? => true)
      expected = ["We do not yet have all the contact details for this route. If you submit a problem",
                  "here relating to <strong>Test Operator Two</strong>, the subject and description of",
                  "the problem will be public, but it will <strong>not</strong> be sent to them. If your problem relates to <strong>Test",
                  "Operator One</strong>, it will be sent straight away."].join(' ')
      expect_advice(mock_problem, expected)
    end
        
    it 'should generate advice text for a train station with no operators' do 
      mock_station = mock_model(Stop, :transport_mode_names => ['Train'])
      mock_problem = mock_model(Problem, :location => mock_station, 
                                         :responsible_organizations => [])
      expected = ["We do not yet know who is responsible for this station. If you submit a problem here",
                  "the subject and description of the problem will be public, but it will <strong>not</strong>",
                  "be sent to them."].join(' ')
      expect_advice(mock_problem, expected)
    end
    
  end
  
end