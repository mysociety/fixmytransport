require 'spec_helper'

describe ProfilesController do

  describe 'GET #show' do 
    
    def make_request(params={:id => 55})
      get :show, params
    end  
    
    describe 'if the user whose profile is requested is not registered' do 

      before do 
        @user = mock_model(User, :registered? => false,
                                 :is_hidden? => false)
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
                                 :name => "Test User",
                                 :is_hidden? => false)
        User.should_receive(:find).with('55', :conditions => ['login_count > 0']).and_return(@user)
      end
      
      it 'should render the "show" template' do 
        make_request
      end

    end
    
    describe 'if the user whose profile is requested is hidden' do 
    
      before do 
        @user = mock_model(User, :is_hidden? => true,
                                 :login_count => 3)
        User.stub!(:find).and_return(@user)
      end
      
      it 'should return a 404' do 
        make_request
        response.status.should == '404 Not Found'
      end
      
    end

    describe 'if the user whose profile is requested is suspended' do 
      
      integrate_views
      
      before do 
        @user = mock_model(User, :registered? => true,
                                 :suspended? => true,
                                 :is_hidden? => false,
                                 :is_expert? => false,
                                 :is_admin? => false,
                                 :suspended_reason => "User used too many rude words",
                                 :suspended_hide_contribs => false,
                                 :name => "Test User",
                                 :profile_photo => mock('profile photo', :url => 'http://www.example.com'),
                                 :location => nil,
                                 :bio => nil, 
                                 :initiated_campaigns => mock('initiated campaigns', :visible => []),
                                 :campaigns => mock('campaigns', :visible => []),
                                 :problems => mock('problems', :visible => []))
        User.should_receive(:find).with('55', :conditions => ['login_count > 0']).and_return(@user)
      end
      
      it 'should display the suspended notice and the reason for suspension' do 
        make_request
        response.should have_tag("div.user-suspended")
      end
          
    end
        
  end

end