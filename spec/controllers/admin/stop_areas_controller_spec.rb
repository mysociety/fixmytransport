require 'spec_helper'

describe Admin::StopAreasController do

  describe 'GET #show' do

    before do
      @default_params = { :id => 22 }
    end

    def make_request(params=@default_params)
      get :show, params
    end

    it 'should ask for a stop in the current generation with the id given' do
      current = mock('current generation')
      StopArea.stub!(:current).and_return(current)
      current.should_receive(:find).with("22")
      make_request
    end

  end

end