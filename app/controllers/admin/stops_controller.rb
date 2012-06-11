class Admin::StopsController < Admin::AdminController

  cache_sweeper :stop_sweeper
  before_filter :require_can_admin_locations, :except => :autocomplete_for_name

  def show
    @stop = Stop.current.find(params[:id])
  end

  def index
    conditions = []
    if !params[:query].blank? or !params[:mode].blank?
      conditions = Stop.name_or_id_conditions(params[:query], params[:mode])
    end
    @stops = Stop.current.paginate :page => params[:page],
                                   :conditions => conditions,
                                   :include => :locality,
                                   :order => 'lower(common_name)'
  end

  def new
    @stop = Stop.new(:loaded => true)
  end

  def create
    @stop = Stop.new(params[:stop])
    if @stop.save
      flash[:notice] = t('admin.stop_created')
      redirect_to(admin_url(admin_stop_path(@stop.id)))
    else
      render :new
    end
  end

  def update
    @stop = Stop.find(params[:id])
    if @stop.update_attributes(params[:stop])
      flash[:notice] = t('admin.stop_updated')
      redirect_to admin_url(admin_stop_path(@stop.id))
    else
      flash[:error] = t('admin.stop_problem')
      render :show
    end
  end

  def destroy
    @stop = Stop.find(params[:id])
    if @stop.campaigns.size > 0 || @stop.problems.size > 0
      flash.now[:error] = t('admin.stop_has_campaigns')
      render :show
    elsif @stop.routes.size > 0
      flash.now[:error] = t('admin.stop_has_routes')
      render :show
    else
      @stop.destroy
      flash[:notice] = t('admin.stop_destroyed')
      redirect_to admin_url(admin_stops_path)
    end
  end

  def autocomplete_for_name
    query = params[:term].downcase
    stops = Stop.find_current_by_name_or_id(query, params[:transport_mode_id], 20, show_all_metro=true)
    stops = stops.map do |stop|
      { :id => stop.id,
        :name => @template.stop_name_for_admin(stop) }
    end
    render :json => stops
  end

end