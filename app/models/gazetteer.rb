class Gazetteer 
  
  def self.find(name)
    localities = Locality.find_all_by_name(name)
  end
  
end