# == Schema Information
# Schema version: 20100707152350
#
# Table name: routes
#
#  id                :integer         not null, primary key
#  transport_mode_id :integer
#  number            :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  type              :string(255)
#  name              :string(255)
#  region_id         :integer
#  cached_slug       :string(255)
#  operator_code     :string(255)
#  loaded            :boolean
#

class TrainRoute < Route
  
  def self.find_existing(route)
    self.find_existing_train_routes(route)
  end
  
  def name(from_stop=nil, short=false)
    return self[:name] if !self[:name].blank?
    name_by_terminuses(transport_mode, from_stop=from_stop, short=short)
  end
  
  def description
    name
  end
  
end
