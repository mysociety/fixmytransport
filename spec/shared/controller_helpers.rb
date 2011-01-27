module SharedBehaviours
  
  module ControllerHelpers
    
    shared_examples_for "an action that requires the campaign initiator" do 

      describe 'when the current user is not the campaign initiator' do

        before do 
          @campaign_user = mock_model(User, :name => "Campaign User")
          @mock_campaign = mock_model(Campaign, :initiator => @campaign_user,
                                                :editable? => true, 
                                                :visible? => true)
          Campaign.stub!(:find).and_return(@mock_campaign)
        end

        describe 'when there is a current user' do 

          it 'should render the "wrong user template"' do 
            controller.stub!(:current_user).and_return(mock_model(User))
            make_request @default_params
            response.should render_template("shared/wrong_user")
          end

          it 'should show an appropriate message' do 
            controller.stub!(:current_user).and_return(mock_model(User))
            make_request @default_params
            assigns[:access_message].should == @expected_access_message 
          end

        end
      end
    end
  end
end
