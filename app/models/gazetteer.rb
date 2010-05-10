class Gazetteer 
  
  def self.find_stops_from_attributes(attributes)
    localities = Locality.find_all_by_name(attributes[:area])
    localities.map{ |locality| locality.stops }.flatten.uniq
  end
  
end