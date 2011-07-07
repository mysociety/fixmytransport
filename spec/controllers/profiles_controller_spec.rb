require 'spec_helper'

describe ProfilesController do

  describe 'GET #show' do 
    
    def make_request(params={:id => 55})
      get :show, params
    end  
    
    describe 'if the user whose profile is requested is not registered' do 

      before do 
        @user = mock_model(User, :registered? => false)
        User.should_receive(:find).with('55', :conditions => ['login_count > 0']).and_return(nil)
      end
    
      it 'should return "not found"' do 
        make_request
        response.status.should == '404 Not Found'
      end
    
    end
    
    describe 'if the user whose profile is requested is registered' do 
      
      before do 
        @user = mock_model(User, :registered? => true,
                                 :name => "Test User")
        User.should_receive(:find).with('55', :conditions => ['login_count > 0']).and_return(@user)
      end
      
      it 'should render the "show" template' do 
        make_request
      end
    
    end
    
  end

end