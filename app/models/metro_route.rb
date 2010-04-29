class MetroRoute < Route
  
  def self.find_existing(route)
    self.find_all_by_number_and_common_stop(route)
  end

end