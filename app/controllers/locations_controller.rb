class LocationsController < ApplicationController
  
  def random
    location_search.close if location_search
    instance = model_class.find :first, :offset => rand(model_class.count)
    redirect_to location_url(instance)
  end

  private
  
  def update_location(location, attributes)
    if location.update_attributes(:campaigns_attributes => attributes[:campaigns_attributes])
      flash[:notice] = t(:confirmation_sent)
      redirect_to location_url(location)
    else
      @new_campaign = location.campaigns.detect{ |campaign| campaign.new_record? }
      render :show 
    end
  end
  
end