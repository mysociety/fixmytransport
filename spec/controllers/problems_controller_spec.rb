require 'spec_helper'

describe ProblemsController do

  describe 'GET #new' do 
    
    def make_request
      get :new 
    end  
  
    it 'should ask for a new problem' do 
      problem = mock_model(Problem, :build_reporter => true)
      Problem.should_receive(:new).and_return(problem)
      make_request
    end
    
  end
  
  describe 'POST #create' do 
  end
  
  describe 'POST #find' do 
  
    before do 
      @stop = mock_model(Stop)
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
      post :find, {:problem => {:transport_mode_id => 5, 
                                :location_attributes => 
                                  {:name => 'My stop', 
                                   :area => 'My town'}}}
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
      response.should redirect_to(stop_url(@stop))
    end
    
  end
  
  describe 'GET #index' do

    def make_request
      get :index
    end
    
    it 'should render the problems/index template' do 
      make_request
      response.should render_template("problems/index")
    end
    
    it 'should ask for problems' do 
      Problem.should_receive(:find).and_return([])
      make_request
    end
  
  end
  
  describe 'GET #show' do 
  
    before do
      @problem = mock_model(Problem, :id => 8, :subject => 'A test problem')
      Problem.stub!(:find).and_return(@problem)
    end
    
    def make_request
      get :show, :id => 8
    end
    
    it 'should ask for the problem by id' do 
      Problem.should_receive(:find).with('8').and_return(@problem)
      make_request
    end
  
    it 'should return a "Not found" response for a request for an invalid ID' do
      Problem.stub!(:find).with('8').and_raise ActiveRecord::RecordNotFound 
      make_request
      response.response_code.should == 404
    end
  
  end

end
