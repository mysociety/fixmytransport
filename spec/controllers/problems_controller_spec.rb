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
      @stop = mock_model(Stop, :locality => mock_model(Locality))
      @problem = mock_model(Problem, :id => 8, 
                                     :subject => 'A test problem', 
                                     :valid? => true, 
                                     :location_from_attributes => mock_model(Stop),
                                     :locations => [@stop], 
                                     :locations= => true,
                                     :location_attributes= => true,
                                     :location_type => 'Stop')
      Problem.stub!(:new).and_return(@problem)
    end
    
    def make_request
      post :find, { :problem => { :transport_mode_id => 5, 
                                  :location_attributes => 
                                  { :name => 'My stop', 
                                    :area => 'My town'} } }
    end
  
    it 'should create a new problem' do 
      Problem.should_receive(:new).and_return(@problem)
      make_request
    end
    
    it 'should try and validate the new problem' do 
      @problem.should_receive(:valid?)
      make_request
    end
    
    it 'should render the "Choose location" view if more than one location is found' do 
      @problem.stub!(:valid?).and_return(true)
      @problem.stub!(:locations).and_return([mock_model(Route, :name => 'a test route'), 
                                             mock_model(Stop, :name => 'a test stop')])
      make_request
      response.should render_template('problems/choose_location')
    end
    
    it 'should redirect to the location page if the problem is valid and the location found' do 
      @problem.stub!(:valid?).and_return(true)
      make_request
      response.should redirect_to(stop_url(@stop.locality, @stop))
    end
    
  end
  
  describe "POST #create" do 

    before do 
      @stop = stops(:victoria_station_one)
      @mock_user = mock_model(User)
      @mock_problem = mock_model(Problem, :save => true, 
                                          :location => @stop,
                                          :reporter => @mock_user, 
                                          :create_assignment => true)
      Problem.stub!(:new).and_return(@mock_problem)
      @mock_assignment = mock_model(Assignment)
      Assignment.stub!(:create_assignment).and_return(@mock_assignment)
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
      flash[:notice].should == "We've sent you an email to confirm that you want to create this problem. We'll hold on to it while you're checking your email."
    end
    
    it 'should redirect to the problem location page if the problem can be saved' do 
      make_request
      response.should redirect_to(stop_url(@stop.locality, @stop))
    end
    
    it 'should create an assignment associated with the problem' do 
      @mock_problem.should_receive(:create_assignment).and_return(@mock_assignment)
      make_request
    end
    
  end
  
   describe "GET #confirm" do 
     
     before do 
       @mock_assignment = mock_model(Assignment)
       @mock_problem = mock_model(Problem, :update_attributes => true, :assignments => [@mock_assignment])
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
     
     it 'should set the confirmed flag and confirmed time on the problem' do 
       @mock_problem.should_receive(:update_attributes).with(:confirmed => true, :confirmed_at => anything)
       make_request
     end
     
     it 'should set the "write-to-operator" and the "publish-problem" assignments associated with this user and problem as complete' do 
       Assignment.should_receive(:complete_problem_assignments).with(@mock_problem, ['write-to-transport-operator', 'publish-problem'])
       make_request
     end
     
   end
  
end