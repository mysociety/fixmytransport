# == Schema Information
# Schema version: 20100707152350
#
# Table name: districts
#
#  id                    :integer         not null, primary key
#  code                  :string(255)
#  name                  :text
#  admin_area_id         :integer
#  creation_datetime     :datetime
#  modification_datetime :datetime
#  revision_number       :string(255)
#  modification          :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#

class District < ActiveRecord::Base
  belongs_to :admin_area
  has_many :localities
  
  # instance methods
  def full_name
    text = name
    if !admin_area.blank?
      text += ", #{admin_area.name}"
    end
    text
  end
  
  # class methods
  def self.get_name_and_admin_area_name(name)
    name = name.downcase
     name_parts = name.split(',', 2)
     if name_parts.size == 2
       name = name_parts.first.strip
       admin_area_name = name_parts.second.strip
     else
       admin_area_name = nil
     end
     [name, admin_area_name]
  end
  
  def self.find_all_by_full_name(name)
    name, admin_area_name = self.get_name_and_admin_area_name(name)
    query_string = "LOWER(districts.name) = ?"
    params = [name]
    includes = [:localities]
    if admin_area_name
      query_string += " AND LOWER(admin_areas.name) = ?"
      params << admin_area_name
      includes << :admin_area
    end
    conditions = [query_string] + params
    districts = self.find(:all, :conditions => conditions, 
                                :include => includes)
    districts.select{ |district| ! district.localities.empty? }                
                    
  end

end
