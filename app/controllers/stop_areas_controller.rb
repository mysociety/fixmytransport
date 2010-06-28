class StopAreasController < LocationsController
  
  def show
    @stop_area = StopArea.full_find(params[:id], params[:scope])
    @new_story = Story.new(:reporter => User.new)
    @title = @stop_area.name
    if location_search
      location_search.add_location(@stop_area) 
      if @stop_area.transport_mode_ids.include? location_search.transport_mode_id
        @new_story.transport_mode_id = location_search.transport_mode_id
      end
    end
    respond_to do |format|
      format.html
      format.atom do  
        @stories = @stop_area.stories.confirmed
        render :template => 'shared/stories.atom.builder', :layout => false 
      end
    end
  end
  
  def update
    @stop_area = StopArea.full_find(params[:id], params[:scope])
    update_location(@stop_area, params[:stop_area])
  end
  
  private
  
  def model_class
    StopArea
  end
  
end