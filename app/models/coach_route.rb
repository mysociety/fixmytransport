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

class CoachRoute < Route
  
  def self.find_existing(route)
    self.find_existing_routes(route)
  end
  
  def name(from_stop=nil, short=false)
    return self[:name] if !self[:name].blank?
    if from_stop
      return number
    elsif short
      return "#{number} coach"
    else
      return "Number #{number} coach route"
    end
  end
  
end
