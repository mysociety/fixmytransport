require 'spec_helper'

describe OutgoingMessagesController do

  describe "GET #new" do 
    
    before do 
      @default_params = { :id => 55, :campaign_id => 66 }
      @campaign_user = mock_model(User, :name => "Campaign User")
      @mock_campaign = mock_model(Campaign, :confirmed => true,
                                            :initiator => @campaign_user)
      @controller.stub!(:current_user).and_return(@campaign_user)
      Campaign.stub!(:find).and_return(@mock_campaign)
      @expected_access_message = :new_access_message
    end
    
    def make_request params
      get :new, params 
    end
    
    it 'should render the template "new"' do 
      make_request @default_params
      response.should render_template('new')
    end
    
    it_should_behave_like "an action that requires the campaign initiator"
  
  end
  
end