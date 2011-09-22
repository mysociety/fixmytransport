class Admin::StopAreasController < Admin::AdminController
  
  cache_sweeper :stop_area_sweeper
  
  def show 
    @stop_area = StopArea.find(params[:id])
  end
  
  def index
    conditions = []
    if !params[:query].blank? or !params[:mode].blank?
      conditions = StopArea.name_or_id_conditions(params[:query], params[:mode])
    end
    @stop_areas = StopArea.paginate :page => params[:page], 
                                    :conditions => conditions, 
                                    :include => :locality,
                                    :order => 'lower(name)'
  end
  
  def new
    @stop_area = StopArea.new(:loaded => true)
  end
  
  def create 
    @stop_area = StopArea.new(params[:stop_area])
    if @stop_area.save
      flash[:notice] = t('admin.stop_area_created')
      redirect_to(admin_url(admin_stop_area_path(@stop_area.id)))
    else
      render :new
    end
  end
  
  def update
    @stop_area = StopArea.find(params[:id])
    if @stop_area.update_attributes(params[:stop_area])
      flash[:notice] = t('admin.stop_area_updated')
      add_responsibilities_notice(:stop_area, :stop_area_operators_attributes, 'StopArea', :operator_id, @stop_area)
      redirect_to admin_url(admin_stop_area_path(@stop_area.id))
    else
      flash.now[:error] = t('admin.stop_area_problem')
      render :show
    end
  end
  
  def destroy
    @stop_area = StopArea.find(params[:id])
    if @stop_area.campaigns.size > 0 || @stop_area.problems.size > 0
      flash.now[:error] = t('admin.stop_area_has_campaigns')
      render :show
    elsif @stop_area.routes.size > 0
      flash.now[:error] = t('admin.stop_area_has_routes')
      render :show
    else
      @stop_area.destroy
      flash[:notice] = t('admin.stop_area_destroyed')
      redirect_to admin_url(admin_stop_areas_path)
    end
  end
  
  def autocomplete_for_name
    query = params[:term].downcase
    stop_areas = StopArea.find_by_name_or_id(query, params[:transport_mode_id], 20)
    stop_areas = stop_areas.map do |stop_area| 
      { :id => stop_area.id, 
        :name => @template.stop_area_name_for_admin(stop_area) } 
    end
    render :json => stop_areas
  end

end