# == Schema Information
# Schema version: 20100506162135
#
# Table name: transport_mode_stop_area_types
#
#  id                :integer         not null, primary key
#  transport_mode_id :integer
#  stop_area_type_id :integer
#  created_at        :datetime
#  updated_at        :datetime
#

class TransportModeStopAreaType < ActiveRecord::Base
  belongs_to :stop_area_type
  belongs_to :transport_mode
end
