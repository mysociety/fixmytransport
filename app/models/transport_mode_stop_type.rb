class TransportModeStopType < ActiveRecord::Base
  belongs_to :stop_type
  belongs_to :transport_mode
end
