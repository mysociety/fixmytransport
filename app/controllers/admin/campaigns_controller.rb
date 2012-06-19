class Admin::CampaignsController < Admin::AdminController

  helper_method :sort_column, :sort_direction
  before_filter :require_can_admin_issues

  def show
    @campaign = Campaign.find(params[:id])
  end

  def index
    conditions = []
    query_clauses = []
    if params[:query]
      query = params[:query].downcase
      query_clause = "(lower(title) like ? or lower(key) like ? "
      2.times { conditions << "%%#{query}%%" }
      # numeric?
      if query.to_i.to_s == query
        query_clause += " OR id = ?"
        conditions << query.to_i
      end
      query_clause += ")"
      query_clauses << query_clause
    end
    conditions = [query_clauses.join(" AND ")] + conditions
    @campaigns = Campaign.paginate :page => params[:page],
                                   :conditions => conditions,
                                   :include => [:problem],
                                   :order => "#{sort_column} #{sort_direction}"
  end

  def update
    @campaign = Campaign.find(params[:id])
    @campaign.status_code = params[:campaign][:status_code]
    if @campaign.update_attributes(params[:campaign])
      flash[:notice] = t('admin.campaign_updated')
      redirect_to admin_url(admin_campaign_path(@campaign.id))
    else
      flash[:error] = t('admin.campaign_problem')
      render :show
    end
  end

  def sort_column
    columns = Campaign.column_names
    columns.include?(params[:sort]) ? params[:sort] : "id"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end

end