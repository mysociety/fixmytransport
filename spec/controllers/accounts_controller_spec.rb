require 'spec_helper'

describe AccountsController do
  
  shared_examples_for "an action requiring a logged-in user" do 
  
    it 'should require a logged-in user' do
      make_request
      flash[:notice].should == 'You must be logged in to access this page.'
    end
    
  end
  
  describe 'GET #show' do 
  
    def make_request
      get :show
    end
  
    it_should_behave_like 'an action requiring a logged-in user'
    
  end
  
  describe 'GET #edit' do

    def make_request
      get :edit
    end
    
    it_should_behave_like 'an action requiring a logged-in user'
    
    describe 'when a user is logged in' do
    
      before do 
        @mock_user = mock_model(User, :errors => mock('errors', :on => []),
                                      :name => '',
                                      :email => '',
                                      :password => '',
                                      :password_confirmation => '')
        controller.stub!(:current_user).and_return(@mock_user)
      end
      
      it 'should render the edit template' do 
        make_request
        response.should render_template("edit")
      end
    
    end
    
  end

  describe 'PUT #update' do 
    
    def make_request
      put :update, { :user => { :email => 'test@example.com' } }
    end

    it_should_behave_like 'an action requiring a logged-in user'    
    
    describe 'when a user is logged in' do 
      
      before do 
        @mock_user = mock_model(User, :email= => true, 
                                      :password= => true,
                                      :password_confirmation= => true,
                                      :save => true)
        controller.stub!(:current_user).and_return(@mock_user)
      end
    
      it 'should update the current users account info' do 
        @mock_user.should_receive(:email=).with('test@example.com')
        make_request
      end
      
      describe 'if the update is successful' do 
        
        it 'should redirect to the account page' do 
          make_request
          response.should redirect_to(account_path)
        end
        
      end
      
      describe 'if the update is not successful' do 
        
        before do 
          @mock_user.stub!(:save).and_return(false)
        end
      
        it 'should render the edit template' do 
          make_request
          response.should render_template('edit')
        end
        
      end
      
    end
    

  end

  
end