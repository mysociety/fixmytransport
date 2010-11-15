require 'spec_helper'

describe LocationsController do

  describe 'GET #show_stop_area' do
    
    def make_request
      get :show_stop_area, { :type => :stop_area, :scope => 'london', :id => 'euston' }
    end
    
    it 'should redirect to a station url if the stop area is a train station' do 
      mock_stop_area = mock_model(StopArea, :area_type => 'GRLS', :locality => 'london')
      StopArea.stub!(:full_find).and_return(mock_stop_area)
      make_request
      response.should redirect_to(station_url(mock_stop_area.locality, mock_stop_area))
    end
    
    it 'should redirect to a station url if the stop area is a metro station' do
      mock_stop_area = mock_model(StopArea, :area_type => 'GTMU', :locality => 'london')
      StopArea.stub!(:full_find).and_return(mock_stop_area)
      make_request
      response.should redirect_to(station_url(mock_stop_area.locality, mock_stop_area))
    end
    
    it 'should redirect to a ferry terminal url if the stop area is a ferry terminal' do 
      mock_stop_area = mock_model(StopArea, :area_type => 'GFTD', :locality => 'london')
      StopArea.stub!(:full_find).and_return(mock_stop_area)
      make_request
      response.should redirect_to(ferry_terminal_url(mock_stop_area.locality, mock_stop_area))
    end
    
  end
  
  describe 'GET #show_route' do 
    
    fixtures default_fixtures
    
    before do 
      @route = routes(:victoria_to_haywards_heath)
    end
    
    def make_request(params)
      get :show_route, params
    end
    
    it 'should not find a route by its id' do 
      make_request({:id => @route.id, :scope => 'great-britain'})
      response.status.should == '404 Not Found'
    end
    
  end
  
end