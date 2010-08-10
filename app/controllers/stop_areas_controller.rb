class StopAreasController < LocationsController
  
  def show
    @stop_area = StopArea.full_find(params[:id], params[:scope])
    @title = @stop_area.name
    if location_search
      location_search.add_location(@stop_area) 
    end
    respond_to do |format|
      format.html
      format.atom do  
        @campaigns = @stop_area.campaigns.confirmed
        render :template => 'shared/campaigns.atom.builder', :layout => false 
      end
    end
  end
  
  private
  
  def model_class
    StopArea
  end
  
end