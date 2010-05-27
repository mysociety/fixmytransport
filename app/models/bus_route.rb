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

class BusRoute < Route

  def self.find_existing(route)
    self.find_existing_routes(route)
  end
  
  def name(from_stop=nil, short=false)
    if from_stop
      return number
    elsif short
      return "#{number} bus"
    else
      return "Number #{number} bus route"
    end
  end

end
