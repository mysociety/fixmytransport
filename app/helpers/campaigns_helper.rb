module CampaignsHelper

  def supporter_initiator_view(campaign)
    return false if params[:preview]
    current_user && current_user.supporter_or_initiator(campaign)
  end
  
  def initiator_view(campaign)
    return false if params[:preview]
    current_user && current_user == campaign.initiator 
  end

end