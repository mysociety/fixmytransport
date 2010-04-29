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
        "Train between #{terminuses.to_sentence}"
      end
    else
      terminuses = route_stops.terminuses.map{ |terminus| terminus.name }
      "Train route between #{terminuses.to_sentence}"     
    end 
  end
  
end