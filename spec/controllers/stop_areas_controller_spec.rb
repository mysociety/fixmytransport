require 'spec_helper'

describe StopAreasController do

  describe 'GET #show' do
    
    def make_request
      get :show, { :type => :stop_area, :scope => 'london', :id => 'euston' }
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
end