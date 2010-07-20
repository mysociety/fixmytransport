class CampaignSweeper < ActionController::Caching::Sweeper
  observe Campaign

  # If our sweeper detects that a Campaign was updated call this
  def after_update(campaign)
    if campaign.confirmed? 
      expire_cache_for(campaign)
    end
  end

  private
  
  def expire_cache_for(campaign)
    # Expire the recent campaigns
    expire_fragment('recent_campaigns')
  end
  
end