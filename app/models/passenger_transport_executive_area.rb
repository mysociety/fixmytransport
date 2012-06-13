class PassengerTransportExecutiveArea < ActiveRecord::Base
  # This model is part of the transport data that is versioned by data generations.
  # This means they have a default scope of models valid in the current data generation.
  # See lib/fixmytransport/data_generations
  exists_in_data_generation( :identity_fields => [],
                             :descriptor_fields => [] )

  belongs_to :pte, :class_name => "PassengerTransportExecutive", :foreign_key => :passenger_transport_executive_id
  has_paper_trail
end
