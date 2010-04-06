require 'spec_helper'

describe HomeController do

  describe 'GET #index' do

    def make_request
      get :index
    end
    
    it 'should render the home/index template' do 
      make_request
      response.should render_template("home/index")
    end
  
  end

end
