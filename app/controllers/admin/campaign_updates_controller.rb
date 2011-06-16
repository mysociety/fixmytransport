class Admin::CampaignUpdatesController < Admin::AdminController

  def show
    @campaign_update = CampaignUpdate.find(params[:id])
  end

  def update
    @campaign_update = CampaignUpdate.find(params[:id])
    if @campaign_update.update_attributes(params[:campaign_update])
      flash[:notice] = t(:campaign_update_updated)
      redirect_to admin_url(admin_campaign_update_path(@campaign_update.id))
    else
      flash[:error] = t(:campaign_update_problem)
      render :show
    end
  end

end