require 'spec_helper'

describe Admin::AccountsController do
  
  describe 'GET #edit' do 
    
    def make_request
      get :edit
    end
    
    before do 
      @mock_admin_user = mock_model(AdminUser)
      @mock_user = mock_model(User, :admin_user => @mock_admin_user,
                                    :suspended? => false)
      controller.stub!(:current_user).and_return(@mock_user)
    end
    
    it 'should pass the admin_user record of the current user as admin_user to the view' do 
      make_request
      assigns[:admin_user].should == @mock_admin_user
    end
    
    it 'should render the "edit" template' do
      make_request
      response.should render_template("edit")
    end
    
  end
  
  describe 'PUT #update' do 

    def make_request(params=@default_params)
      put :update, params
    end
    
    before do 
      @default_params = { :admin_user => { :password => 'sekrit', :password_confirmation => 'sekrit_again' } }
      @mock_admin_user = mock_model(AdminUser, :password= => nil,
                                               :password_confirmation= => nil,
                                               :save => nil)
      @mock_user = mock_model(User, :admin_user => @mock_admin_user,
                                    :suspended? => false)
      controller.stub!(:current_user).and_return(@mock_user)
    end
    
    it 'should pass the admin_user record of the current user as admin_user to the view' do 
      make_request
      assigns[:admin_user].should == @mock_admin_user
    end
  
    it 'should set the password and password confirmation fields on the admin_user record' do 
      @mock_admin_user.should_receive(:password=).with('sekrit')
      @mock_admin_user.should_receive(:password_confirmation=).with('sekrit_again')
      make_request
    end
    
    it 'should try and save the record' do 
      @mock_admin_user.should_receive(:save)
      make_request
    end
    
    describe 'if the record can be saved' do 
      
      before do 
        @mock_admin_user.stub!(:save).and_return(true)
        make_request
      end
    
      it 'should redirect to the admin edit path' do 
        @mock_admin_user.stub!(:save).and_return(false)
        make_request
      end
      
    end
    
    describe 'if the record cannot be saved' do 
      
      it 'should render the "edit" template' do 
        make_request
        response.should render_template('edit')
      end
      
    end
    
  end

end