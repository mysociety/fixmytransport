require 'spec_helper'

describe PasswordResetsController do

  shared_examples_for "an action requiring a perishable token" do 
    
    it 'should look for a user by perishable token' do 
      User.should_receive(:find_using_perishable_token)
      make_request
    end
    
    describe 'if no user can be found using the perishable token param' do 
      
      it 'should show a notice saying that the account cannot be found' do 
        make_request
        flash[:notice].should == "We're sorry, but we could not locate your account. If you are having issues try copying and pasting the URL from your email into your browser or restarting the reset password process."
      end
      
      it 'should redirect to the root url' do 
        make_request
        response.should redirect_to(root_url)
      end
      
    end
    
  end
  
  
  describe 'GET #new' do
    
    def make_request
      get :new
    end
    
    it 'should render the "new" template' do 
      make_request
      response.should render_template('new')
    end
     
  end

  describe 'GET #edit' do
    
    def make_request
      get :edit, :id => '1'
    end
  
    it_should_behave_like "an action requiring a perishable token"
    
    describe 'if a user can be found using the perishable token param' do
    
      before do 
        User.stub!(:find_using_perishable_token).with('1').and_return(mock_model(User, :registered? => true))
      end
    
      it 'should render the "edit" template' do 
        make_request
        response.should render_template('edit')
      end
      
    end
     
  end
  
  describe 'POST #create' do 
    
    def make_request
      post :create, :email => 'test@example.com'
    end
    
    it 'should find the user by their email address' do 
      User.should_receive(:find_by_email).with('test@example.com')
      make_request
    end
    
    describe 'if the user is found' do
      
      before do 
        @user = mock_model(User, :deliver_password_reset_instructions! => true)
        User.stub!(:find_by_email).and_return(@user)
      end
      
      it 'should deliver the password reset instructions' do 
        @user.should_receive(:deliver_password_reset_instructions!)
        make_request
      end
      
      it 'should render the "confirmation sent" template' do
        make_request
        response.should render_template('shared/confirmation_sent')
      end
      
      it 'should set the action to be confirmed to changing the password' do 
        make_request
        assigns[:action].should == 'your password will not be changed.'
      end
      
    end
  
    describe 'if the user is not found' do
      
      it 'should display a notice saying the user has not been found' do 
        make_request
        flash[:notice].should == 'No user was found with that email address.'
      end
      
      it 'should render the "new" template' do 
        make_request
        response.should render_template('new')
      end
      
    end
    
  end
  
  describe 'PUT #update' do 
  
    def make_request(session_info = {})
      put :update, { :id => '1', :user => { :password => 'boo', 
                                            :password_confirmation => 'booagain' } }, session_info
    end

    it_should_behave_like "an action requiring a perishable token"
    
    describe 'if a user can be found with the perishable token' do 
    
      before do 
        @user = mock_model(User, :password= => true, 
                                 :password_confirmation= => true,
                                 :registered? => true,
                                 :ignore_blank_passwords= => true, 
                                 :save => true)
        User.stub!(:find_using_perishable_token).and_return(@user)
      end
      
      it 'should set the password and password confirmation on the user' do 
        @user.should_receive(:password=).with('boo')
        @user.should_receive(:password_confirmation=).with('booagain')
        make_request
      end
      
      it 'should check to see if the user saves' do 
        @user.should_receive(:save)
        make_request
      end
      
      describe 'if the user does not save' do 
        
        before do 
          @user.stub!(:save).and_return(false)
        end
        
        it 'should render the "edit" template' do 
          make_request
          response.should render_template("edit")
        end
        
      end
      
      describe 'if the user saves' do
        
        before do 
          @user.stub!(:save).and_return(true)
        end

        it 'should show a notice saying that the password has been updated' do 
          make_request
          flash[:notice].should == 'Your password has been successfully updated.'
        end
        
        it 'should redirect back to the location the user was going when they were last asked to login if one was set' do 
          session_info = { :return_to => campaigns_url }
          make_request session_info
          response.should redirect_to(campaigns_url)
        end
        
        it 'should redirect back to the root url if no redirect location has been set for the user' do 
          make_request
          response.should redirect_to(root_url)
        end
      
      end
      
    end
    
  end
    
end