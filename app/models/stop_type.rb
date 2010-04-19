# == Schema Information
# Schema version: 20100414172905
#
# Table name: stop_types
#
#  id                :integer         not null, primary key
#  code              :string(255)
#  description       :string(255)
#  on_street         :boolean
#  point_type        :string(255)
#  version           :float
#  created_at        :datetime
#  updated_at        :datetime
#  transport_mode_id :integer
#

class StopType < ActiveRecord::Base
  belongs_to :transport_mode
  
  def self.codes_for_transport_mode(transport_mode_id)
    stop_types = find_all_by_transport_mode_id(transport_mode_id)
    stop_types.map{ |stop_type| stop_type.code }
  end
  
end
