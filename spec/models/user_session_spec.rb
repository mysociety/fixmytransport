require 'spec_helper'

describe UserSession do

  describe 'when logging in a user by confirmation' do 
    
    before do
      @user = mock_model(User, :suspended? => false)
      @user_session = mock_model(UserSession, :save => nil)
      UserSession.stub!(:new).and_return(@user_session)
    end
    
    it 'should set httponly on the session (cookie setting)' do 
      @user_session.should_receive(:httponly=).with(true)
      UserSession.login_by_confirmation(@user)
    end
    
    describe 'if the user is suspended' do 
      
      before do
        @user.stub!(:suspended?).and_return(true)
      end
        
      it 'should not create a new session' do 
        UserSession.should_not_receive(:new)
        UserSession.login_by_confirmation(@user)
      end
      
    end
    
  end
  
end