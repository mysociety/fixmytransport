class RouteSource < ActiveRecord::Base
  # This model is part of the transport data that is versioned by data generations.
  # This means they have a default scope of models valid in the current data generation.
  # See lib/fixmytransport/data_generation
  exists_in_data_generation()
  belongs_to :region, :conditions => Region.data_generation_conditions
  belongs_to :route, :conditions => Route.data_generation_conditions
end