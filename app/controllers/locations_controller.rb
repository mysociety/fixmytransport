class LocationsController < ApplicationController
  
  def random
    location_search.close if location_search
    instance = model_class.find :first, :offset => rand(model_class.count)
    redirect_to location_url(instance)
  end
  
end