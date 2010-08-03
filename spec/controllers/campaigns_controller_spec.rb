require 'spec_helper'

describe CampaignsController do

  describe 'GET #new' do 
    
    def make_request
      get :new 
    end  
  
    it 'should ask for a new campaign' do 
      campaign = mock_model(Campaign, :build_reporter => true)
      Campaign.should_receive(:new).and_return(campaign)
      make_request
    end
    
  end
  
  describe 'POST #create' do 
  end
  
  describe 'POST #find' do 
  
    before do 
      @stop = mock_model(Stop, :locality => mock_model(Locality))
      @campaign = mock_model(Campaign, :id => 8, 
                                     :title => 'A test campaign', 
                                     :valid? => true, 
                                     :location_from_attributes => mock_model(Stop),
                                     :locations => [@stop], 
                                     :locations= => true,
                                     :location_attributes= => true,
                                     :location_type => 'Stop')
      Campaign.stub!(:new).and_return(@campaign)
    end
    
    def make_request
      post :find, {:campaign => {:transport_mode_id => 5, 
                                :location_attributes => 
                                  {:name => 'My stop', 
                                   :area => 'My town'}}}
    end
  
    it 'should create a new campaign' do 
      Campaign.should_receive(:new).and_return(@campaign)
      make_request
    end
    
    it 'should try and validate the new campaign' do 
      @campaign.should_receive(:valid?)
      make_request
    end
    
    it 'should render the "Choose location" view if more than one location is found' do 
      @campaign.stub!(:valid?).and_return(true)
      @campaign.stub!(:locations).and_return([mock_model(Route, :name => 'a test route'), 
                                             mock_model(Stop, :name => 'a test stop')])
      make_request
      response.should render_template('campaigns/choose_location')
    end
    
    it 'should redirect to the location page if the campaign is valid and the location found' do 
      @campaign.stub!(:valid?).and_return(true)
      make_request
      response.should redirect_to(stop_url(@stop.locality, @stop))
    end
    
  end
  
  describe 'GET #index' do

    def make_request
      get :index
    end
    
    it 'should render the campaigns/index template' do 
      make_request
      response.should render_template("campaigns/index")
    end
    
    it 'should ask for campaigns' do 
      Campaign.should_receive(:find).and_return([])
      make_request
    end
  
  end
  
  describe 'GET #show' do 
  
    before do
      @campaign = mock_model(Campaign, :id => 8, :title => 'A test campaign')
      Campaign.stub!(:find).and_return(@campaign)
    end
    
    def make_request
      get :show, :id => 8
    end
    
    it 'should ask for the campaign by id' do 
      Campaign.should_receive(:find).with('8').and_return(@campaign)
      make_request
    end
  
    it 'should return a "Not found" response for a request for an invalid ID' do
      Campaign.stub!(:find).with('8').and_raise ActiveRecord::RecordNotFound 
      make_request
      response.response_code.should == 404
    end
  
  end

end
