module SharedBehaviours
  
  module ControllerHelpers
    
    shared_examples_for "add_comment when an invalid comment has been submitted" do

      describe 'when handling a request asking for HTML' do 

        it 'should render the "add_comment" template' do 
          make_request(default_params)
          response.should render_template("shared/add_comment")
        end

      end

      describe 'when responding to a request asking for json' do 

        it 'should return a json hash with the key success set to false' do 
          make_request(default_params.update(:format => 'json'))
          json_hash = JSON.parse(response.body)
          json_hash['success'].should == false
        end

        it 'should return a json hash with the error messages' do 
          make_request(default_params.update(:format => 'json'))
          json_hash = JSON.parse(response.body)
          json_hash['errors']['text'].should == "Please enter some text"
        end

      end

    end
    
    shared_examples_for "an action that requires the campaign initiator" do 

      describe 'when there is a current user' do 
         
        describe 'and the current user is not the campaign initiator' do

          before do 
            @campaign_user = mock_model(User, :name => "Campaign User")
            @mock_campaign = mock_model(Campaign, :initiator => @campaign_user,
                                                  :editable? => true, 
                                                  :status => :confirmed,
                                                  :visible? => true)
            Campaign.stub!(:find).and_return(@mock_campaign)
            controller.stub!(:current_user).and_return(mock_model(User, :is_expert? => false))
          end
          
          it 'should render the "wrong user template"' do 
            make_request @default_params
            response.should render_template("shared/wrong_user")
          end

          it 'should show an appropriate message' do 
            make_request @default_params
            assigns[:access_message].should == "shared.access.#{@expected_access_message}"
          end
          
        end
      end

      describe 'when there is no current user' do
        
        before do 
          controller.stub!(:current_user).and_return(nil)
        end

        it 'should redirect to the login page with a message' do
          make_request(@default_params)
          response.should redirect_to(login_url)
          assigns[:access_message].should == "shared.access.#{@expected_access_message}"
        end
        
      end
    end
    
    shared_examples_for "an action requiring a visible campaign" do 
    
      it 'should return a 404 for a campaign that is not visible' do 
        @invisible_campaign = mock_model(Campaign, :editable? => true, 
                                                   :visible? => false)
        Campaign.stub!(:find).and_return(@invisible_campaign)
        make_request
        response.status.should == '404 Not Found'
      end
      
    end
    
    shared_examples_for "an action that receives a POSTed comment" do 
      
      describe 'if there is no current user' do 

        it 'should validate the comment  skipping user name validation' do 
          @mock_comment.should_receive(:skip_name_validation=).with(true)
          make_request(default_params)
        end

        describe 'if the comment is not valid' do 

          before do 
            @mock_comment.stub!(:valid?).and_return(false)
            @mock_comment.stub!(:errors).and_return([[:text, "Please enter some text"]])
          end

          it_should_behave_like "add_comment when an invalid comment has been submitted"

        end

        describe 'if the comment is valid' do 

          it 'should save the comment data in the session' do 
            controller.should_receive(:data_to_string)
            make_request(default_params)
          end

          describe 'if the request asks for json' do 

            it 'should return a json hash with the success key set to true' do 
              make_request(default_params.update(:format => 'json'))
              json_hash = JSON.parse(response.body)
              json_hash['success'].should == true
            end

            it 'should return a json hash with the requires_login key set to true' do 
              make_request(default_params.update(:format => 'json'))
              json_hash = JSON.parse(response.body)
              json_hash['requires_login'].should == true
            end

            it 'should return a json hash with a key for a message for the user asking them to login' do 
              make_request(default_params.update(:format => 'json'))
              json_hash = JSON.parse(response.body)
              json_hash['notice'].should == @expected_notice
            end

          end

          describe 'if the request asks for html' do 

            it 'should redirect the user to the login page' do 
              make_request(default_params)
              response.should redirect_to(login_url)
            end

            it 'should display a notice for the user asking them to login' do 
              make_request(default_params)
              flash[:notice].should == @expected_notice
            end

          end

        end

      end

      describe 'if there is a current user' do 

        before do 
          @controller.stub!(:current_user).and_return(@mock_user)
        end

        it 'should create a comment associated with the campaign' do
          @mock_comment.commented.comments.should_receive(:build)
          make_request(default_params)
        end

        it 'should set the status of the comment to new' do
          @mock_comment.should_receive(:status=).with(:new)
          make_request(default_params)
        end

        it 'should set the current user as the commenter' do 
          @mock_comment.should_receive(:user=).with(@mock_user)
          make_request(default_params)
        end

        describe 'if the comment is valid' do

          it 'should save the comment' do
            @mock_comment.should_receive(:save).and_return(true)
            make_request(default_params)
          end

          it 'should confirm the comment' do
            @mock_comment.should_receive(:confirm!).and_return(true) 
            make_request(default_params)
          end


          describe 'when handling an html request' do 

            it 'should redirect to the commented url' do 
              make_request(default_params)
              response.should redirect_to @expected_redirect
            end

          end

          describe 'when handling a json request' do 

            it 'should return a json hash containing success and comment html' do
              make_request(default_params.update(:format => 'json'))
              json_hash = JSON.parse(response.body)
              json_hash['success'].should == true
              json_hash['html'].should_not be_nil
            end

          end

        end

        describe 'if the comment is not valid' do 

          before do 
            @mock_comment.stub!(:valid?).and_return(false)
            @mock_comment.stub!(:errors).and_return([[:text, "Please enter some text"]])
          end  

          it_should_behave_like "add_comment when an invalid comment has been submitted"

        end


      end
    
    end
    
  end
end
