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
    self.find_all_by_terminuses_and_stop_set(route)
  end
  
  def name(from_stop=nil)
    if from_stop
      terminuses = route_stops.terminuses.reject{ |terminus| terminus.stop == from_stop }
      terminuses = terminuses.map{ |terminus| terminus.name }
      if terminuses.size == 1
        "Train to #{terminuses.to_sentence}"
      else
        "Train between #{terminuses.sort.to_sentence}"
      end
    else
      terminuses = route_stops.terminuses.map{ |terminus| terminus.name }
      "Train route between #{terminuses.sort.to_sentence}"     
    end 
  end
  
  def description
    name
  end
  
end
