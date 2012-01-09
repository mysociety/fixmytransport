require 'spec_helper'

describe QuestionnairesController do

  describe 'GET #show' do
    
    def make_request
      get :show, { :email_token => 'mytoken' }
    end
    
    before do
      @user = mock_model(User)
      @stop = mock_model(Stop, :points => ['my points'])
      @problem = mock_model(Problem, :location => @stop)
      @questionnaire = mock_model(Questionnaire, :subject => @problem,
                                                 :completed_at => nil,
                                                 :user => @user)
      Questionnaire.stub!(:find_by_token).and_return(@questionnaire)
      controller.stub!(:map_params_from_location)
      UserSession.stub!(:login_by_confirmation).and_return(mock_model(UserSession))
    end
    
    it 'should look for the questionnaire by token' do
      Questionnaire.should_receive(:find_by_token).with('mytoken')
      make_request
    end
    
    describe 'if the questionnaire cannot be found' do
      
      before do
        Questionnaire.stub!(:find_by_token).and_return(nil)
      end
    
      it 'should redirect to the front page' do 
        make_request
        response.should redirect_to(root_url)
      end
      
      it 'should show an error message' do 
        make_request
        flash[:error].should == "We're sorry, but we could not find that questionnaire. If you are having issues, try copying and pasting the URL from your email into your browser. If that doesn't work, use the feedback link to get in touch."
      end
      
    end
    
    describe 'if the questionnaire can be found' do

      it 'should set up map params from the stop' do 
        controller.should_receive(:map_params_from_location).with(@stop.points, find_other_locations=false)
        make_request
      end
      
      it 'should try to log in the questionnaire user' do 
        UserSession.should_receive(:login_by_confirmation)
        make_request
      end
            
      describe 'if login by confirmation does not return a session (indicating the user is suspended)' do      
        
        before do
          UserSession.stub(:login_by_confirmation).and_return(nil)
        end
        
        it 'should show a suspension error message' do 
          make_request
          flash[:error].should == 'Unable to access questionnaire: this account has been suspended.'
        end
        
        it 'should redirect to the front page' do 
          make_request
          response.should redirect_to(root_url)
        end
        
      end
      
      describe 'if login by confirmation returns a session' do  

            
        it "should render the 'show' template" do
          make_request
          response.should render_template('show')
        end
    
        describe 'if the questionnaire has been completed' do 
        
          before do
            @questionnaire.stub!(:completed_at).and_return(Time.now - 1.day)
          end
      
          it 'should show an error message' do 
            make_request
            flash[:error].should match("You've already answered this questionnaire.")
          end
        
          it 'should redirect to the front page' do 
            make_request
            response.should redirect_to(root_url)
          end
        
        end
        
      end
    
    end
    
  end
  
end