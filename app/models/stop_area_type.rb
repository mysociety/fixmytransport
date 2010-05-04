class StopAreaType < ActiveRecord::Base
  has_many :transport_mode_stop_area_types
  has_many :transport_modes, :through => :transport_mode_stop_area_types
end
