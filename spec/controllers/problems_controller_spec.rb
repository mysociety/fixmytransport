require 'spec_helper'

describe ProblemsController do

  describe 'GET #frontpage' do 
    
    def make_request
      get :frontpage 
    end  
  
    it 'should ask for a new problem' do 
      problem = mock_model(Problem, :build_reporter => true)
      Problem.should_receive(:new).and_return(problem)
      make_request
    end
    
  end
  
  describe 'POST #find' do 
  
    before do 
      @mock_stop = mock_model(Stop, :locality => mock_model(Locality))
      @mock_problem = mock_model(Problem, :id => 8, 
                                     :subject => 'A test problem', 
                                     :valid? => true, 
                                     :location_from_attributes => mock_model(Stop),
                                     :locations => [@mock_stop], 
                                     :locations= => true,
                                     :location_attributes= => true,
                                     :location_type => 'Stop')
      Problem.stub!(:new).and_return(@mock_problem)
    end
    
    def make_request
      post :find, { :problem => { :transport_mode_id => 5, 
                                  :location_attributes => 
                                  { :name => 'My stop', 
                                    :area => 'My town'} } }
    end
  
    it 'should create a new problem' do 
      Problem.should_receive(:new).and_return(@mock_problem)
      make_request
    end
    
    it 'should try and validate the new problem' do 
      @mock_problem.should_receive(:valid?)
      make_request
    end
    
    it 'should render the "Choose location" view if more than one location is found' do 
      @mock_problem.stub!(:valid?).and_return(true)
      @mock_problem.stub!(:locations).and_return([mock_model(Route, :name => 'a test route'), 
                                                  mock_model(Stop, :name => 'a test stop')])
      make_request
      response.should render_template('problems/choose_location')
    end
    
    it 'should redirect to the location page if the problem is valid and the location found' do 
      @mock_problem.stub!(:valid?).and_return(true)
      make_request
      response.should redirect_to(stop_url(@mock_stop.locality, @mock_stop))
    end
    
  end
  
  describe "POST #create" do 

    before do 
      @stop = stops(:victoria_station_one)
      @mock_user = mock_model(User)
      @mock_problem = mock_model(Problem, :save => true, 
                                          :location => @stop,
                                          :reporter => @mock_user, 
                                          :create_assignments => true)
      Problem.stub!(:new).and_return(@mock_problem)
      @mock_assignment = mock_model(Assignment)
      Assignment.stub!(:create_assignments).and_return(@mock_assignment)
      @problem_attributes = {}
    end
    
    def make_request
      post :create, { :problem => @problem_attributes }
    end
    
    it 'should create a new problem using the attributes passed to it' do 
      Problem.should_receive(:new).with(@problem_attributes)
      make_request
    end
    
    it 'should try to save the problem' do 
      @mock_problem.should_receive(:save)
      make_request
    end
    
    it 'should render the "new" template if the problem cannot be saved' do 
      @mock_problem.stub!(:save).and_return(false)
      make_request
      response.should render_template('problems/new')
    end
    
    it 'should show the confirmation notice if the problem can be saved' do 
      make_request
      response.flash[:notice].should == "We've sent you an email to confirm that you want to create this problem. We'll hold on to it while you're checking your email."
    end
    
    it 'should render the "confirmation_sent" template if the problem can be saved' do 
      make_request
      response.should render_template('problems/confirmation_sent')
    end
    
    it 'should create assignments associated with the problem' do 
      @mock_problem.should_receive(:create_assignments).and_return(@mock_assignment)
      make_request
    end
    
  end
  
  describe "PUT #update" do 
  
    before do 
      @mock_problem = mock_model(Problem, :update_attributes => true)
      Problem.stub!(:find).and_return(@mock_problem)
    end
    
    def make_request
      put :update, { :id => 55, 
                     :problem => { :title => 'a new title', 
                                   :updates_attributes => { '0' => { :text => 'test' } } } }
    end
    
    it 'should find the problem by id' do 
      Problem.should_receive(:find).with('55')
      make_request
    end
    
    it 'should only pass on parameters for a new update' do 
      @mock_problem.should_receive(:update_attributes).with({ :updates_attributes => 
                                                              { '0' => { 'text' => 'test' }}})
      make_request
    end
    
    it 'should show the confirmation message if the update is valid' do 
      make_request
      response.flash[:notice].should == "We've sent you an email to confirm that you want to add this update. We'll hold on to it while you're checking your email."
    end
    
    it 'should render the "confirmation_sent" template if the update is valid' do 
      make_request
      response.should render_template('problems/confirmation_sent')
    end
    
  end
  
  describe "GET #confirm" do 
     
    before do 
      @mock_assignment = mock_model(Assignment)
      @mock_problem = mock_model(Problem, :update_attributes => true, 
                                          :assignments => [@mock_assignment],
                                          :emailable_organization_info => [])
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

    it 'should set the "write-to-transport-organization" and the "publish-problem" assignments associated with this user and problem as complete' do 
      assignment_data =  { 'write-to-transport-organization' => {}, 
                           'publish-problem' => {} }
      Assignment.should_receive(:complete_problem_assignments).with(@mock_problem, assignment_data)
      make_request
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
                  "<strong>not</strong> be sent to them until you provide their contact details",
                  "(we'll help you do this)."].join(' ')
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
                  "Council until you provide their contact details (we'll help you",
                  "do this)."].join(' ')
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
                                         :operators_responsible? => false)
      expected = ["Your problem will be sent to <strong>Test Council Two</strong>. The subject and",
                  "description of the problem will be public. We do not yet have contact details for",
                  "<strong>Test Council One</strong>, so your problem will not <strong>not</strong>",
                  "be sent to them until you provide their contact details (we'll help you",
                  "do this)."].join(' ')
      expect_advice(mock_problem, expected)
    end
    
    it 'should generate advice text for a bus/coach stop with no responsible organization' do 
      mock_stop = mock_model(Stop, :transport_mode_names => ['Bus', 'Coach'])
      mock_problem = mock_model(Problem, :location => mock_stop, 
                                         :responsible_organizations => [])
      expected = ["We do not yet know who is responsible for this stop. If you submit a problem",
                  "here the subject and description of the problem will be public, but it will",
                  "<strong>not</strong> be sent to them until you provide their details (we'll",
                  "help you do this)."].join(' ')
      expect_advice(mock_problem, expected)
    end
    
    it 'should generate advice text for a bus route with no operators' do
      mock_route = mock_model(Route, :transport_mode_names => ['Bus'])
      mock_problem = mock_model(Problem, :location => mock_route, 
                                         :responsible_organizations => [])
      expected = ["We do not yet know who is responsible for this route. If you submit a problem",
                  "here the subject and description of the problem will be public, but it will",
                  "<strong>not</strong> be sent to them until you provide their details (we'll",
                  "help you do this)."].join(' ')
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
                  "the problem will be public, but it will <strong>not</strong> be sent until you provide",
                  "their contact details (we'll help you do this). If your problem relates to <strong>Test",
                  "Operator One</strong>, it will be sent straight away."].join(' ')
      expect_advice(mock_problem, expected)
    end
        
    it 'should generate advice text for a train station with no operators' do 
      mock_station = mock_model(Stop, :transport_mode_names => ['Train'])
      mock_problem = mock_model(Problem, :location => mock_station, 
                                         :responsible_organizations => [])
      expected = ["We do not yet know who is responsible for this station. If you submit a problem here",
                  "the subject and description of the problem will be public, but it will <strong>not</strong>",
                  "be sent to them until you provide their details (we'll help you do this)."].join(' ')
      expect_advice(mock_problem, expected)
    end
    
  end
  
end