module CampaignsHelper

  def supporter_initiator_view(campaign)
    return false if params[:preview]
    return true if current_user && current_user.supporter_or_initiator(campaign)
    return true if current_user &&
      current_user.is_admin? &&
      current_user.can_admin_issues? &&
      params[:initiator_view] == '1'
    return false
  end

  def initiator_view(campaign)
    return false if params[:preview]
    return true if current_user && current_user == campaign.initiator
    return true if current_user &&
      current_user.is_admin? &&
      current_user.can_admin_issues? &&
      params[:initiator_view] == '1'
    return false
  end

end