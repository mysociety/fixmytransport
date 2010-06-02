# == Schema Information
# Schema version: 20100506162135
#
# Table name: routes
#
#  id                :integer         not null, primary key
#  transport_mode_id :integer
#  number            :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  type              :string(255)
#

class TrainRoute < Route
  
  def self.find_existing(route)
    self.find_existing_train_routes(route)
  end
  
  def name(from_stop=nil, short=false)
    name_by_terminuses(transport_mode, from_stop=from_stop, short=short)
  end
  
  def description
    name
  end
  
end
