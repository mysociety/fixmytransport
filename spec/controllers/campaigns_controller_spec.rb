require 'spec_helper'

describe CampaignsController do

  
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
      mock_assignment = mock_model(Assignment, :task_type_name => 'A test task')
      @campaign = mock_model(Campaign, :id => 8, 
                                       :title => 'A test campaign',
                                       :default_assignment => mock_assignment,
                                       :reporter_id => 44)
      Campaign.stub!(:find).and_return(@campaign)
    end
    
    def make_request
      get :show, :id => 8
    end
    
    it 'should ask for the campaign by id' do 
      Campaign.should_receive(:find).with('8').and_return(@campaign)
      make_request
    end
    
  end

end
