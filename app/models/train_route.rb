class TrainRoute < Route
  
  def self.find_existing(route)
    self.find_all_by_terminuses_and_stop_set(route)
  end
  
  def name
    terminus_phrase = route_stops.terminuses.map{ |terminus| terminus.name }.to_sentence
    "Train route between #{terminus_phrase}"      
  end
  
end