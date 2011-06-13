class Admin::CampaignsController < Admin::AdminController
  
  def show
    @campaign = Campaign.find(params[:id])
  end
  
  def index
    conditions = []
    query_clauses = []
    if params[:query]
      query = params[:query].downcase
      query_clause = "(lower(title) like ?"
      conditions << "%%#{query}%%" 
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
                                   :order => 'id desc'
  end
  
  def update
    @campaign = Campaign.find(params[:id])
    @campaign.status_code = params[:campaign][:status_code]
    if @campaign.update_attributes(params[:campaign])
      flash[:notice] = t(:campaign_updated)
      redirect_to admin_url(admin_campaign_path(@campaign.id))
    else
      flash[:error] = t(:campaign_problem)
      render :show
    end
  end
  
end