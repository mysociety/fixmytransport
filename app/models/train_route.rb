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
  
  def name(from_stop=nil)
    if from_stop
      terminuses = self.terminuses.reject{ |terminus| terminus == from_stop }
      terminuses = terminuses.map{ |terminus| terminus.name_without_station }.uniq
      if terminuses.size == 1
        "Train to #{terminuses.to_sentence}"
      else
        "Train between #{terminuses.sort.to_sentence}"
      end
    else
      terminuses = self.terminuses.map{ |terminus| terminus.name_without_station }.uniq
      "Train route between #{terminuses.sort.to_sentence}"     
    end 
  end
  
  def description
    name
  end
  
end
