class RouteSubRoute < ActiveRecord::Base
  belongs_to :route
  belongs_to :sub_route
  # This model is part of the transport data that is versioned by data generations.
  # This means they have a default scope of models valid in the current data generation.
  # See lib/fixmytransport/data_generations
  exists_in_data_generation()
end
