require 'spec_helper'

describe Admin::UsersController do

  describe 'GET #show' do 
    
    before do 
      @default_params = { :id => 55 }
      @required_admin_permission = :users
    end
    
    def make_request(params=@default_params)
      get :show, params
    end
  
    it_should_behave_like "an action that requires a specific admin permission"
    
  end

  describe 'GET #index' do 
  
    before do 
      @required_admin_permission = :users
      @default_params = {}
    end

    def make_request(params=@default_params)
      get :index, params
    end

    it_should_behave_like "an action that requires a specific admin permission"
    
  end

  describe 'PUT #update' do 
    
    before do 
      @required_admin_permission = :users
      @default_params = { :id => 55 }
    end

    def make_request(params=@default_params)
      put :update, params
    end

    it_should_behave_like "an action that requires a specific admin permission"
    
  end

end