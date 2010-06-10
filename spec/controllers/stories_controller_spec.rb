require 'spec_helper'

describe StoriesController do

  describe 'GET #new' do 
    
    def make_request
      get :new 
    end  
  
    it 'should ask for a new story' do 
      story = mock_model(Story, :build_reporter => true)
      Story.should_receive(:new).and_return(story)
      make_request
    end
    
  end
  
  describe 'POST #create' do 
  end
  
  describe 'POST #find' do 
  
    before do 
      @stop = mock_model(Stop)
      @story = mock_model(Story, :id => 8, 
                                     :subject => 'A test story', 
                                     :valid? => true, 
                                     :location_from_attributes => mock_model(Stop),
                                     :locations => [@stop], 
                                     :locations= => true,
                                     :location_attributes= => true,
                                     :location_type => 'Stop')
      Story.stub!(:new).and_return(@story)
    end
    
    def make_request
      post :find, {:story => {:transport_mode_id => 5, 
                                :location_attributes => 
                                  {:name => 'My stop', 
                                   :area => 'My town'}}}
    end
  
    it 'should create a new story' do 
      Story.should_receive(:new).and_return(@story)
      make_request
    end
    
    it 'should try and validate the new story' do 
      @story.should_receive(:valid?)
      make_request
    end
    
    it 'should render the "Choose location" view if more than one location is found' do 
      @story.stub!(:valid?).and_return(true)
      @story.stub!(:locations).and_return([mock_model(Route, :name => 'a test route'), 
                                             mock_model(Stop, :name => 'a test stop')])
      make_request
      response.should render_template('stories/choose_location')
    end
    
    it 'should redirect to the location page if the story is valid and the location found' do 
      @story.stub!(:valid?).and_return(true)
      make_request
      response.should redirect_to(stop_url(@stop))
    end
    
  end
  
  describe 'GET #index' do

    def make_request
      get :index
    end
    
    it 'should render the stories/index template' do 
      make_request
      response.should render_template("stories/index")
    end
    
    it 'should ask for stories' do 
      Story.should_receive(:find).and_return([])
      make_request
    end
  
  end
  
  describe 'GET #show' do 
  
    before do
      @story = mock_model(Story, :id => 8, :subject => 'A test story')
      Story.stub!(:find).and_return(@story)
    end
    
    def make_request
      get :show, :id => 8
    end
    
    it 'should ask for the story by id' do 
      Story.should_receive(:find).with('8').and_return(@story)
      make_request
    end
  
    it 'should return a "Not found" response for a request for an invalid ID' do
      Story.stub!(:find).with('8').and_raise ActiveRecord::RecordNotFound 
      make_request
      response.response_code.should == 404
    end
  
  end

end
