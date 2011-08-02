# == Schema Information
# Schema version: 20100707152350
#
# Table name: admin_areas
#
#  id                    :integer         not null, primary key
#  code                  :string(255)
#  atco_code             :string(255)
#  name                  :text
#  short_name            :text
#  country               :string(255)
#  national              :boolean
#  creation_datetime     :datetime
#  modification_datetime :datetime
#  revision_number       :string(255)
#  modification          :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#  region_id             :integer
#

class AdminArea < ActiveRecord::Base
  
  belongs_to :region
  has_many :localities
  has_friendly_id :slug_name, :use_slug => true
  
  # instance methods
  
  def slug_name
    return short_name if short_name 
    return name
  end
  
  def full_name
    text = name
    if !region.blank?
      text += ", #{region.name}"
    end
    text
  end
  
  # class methods 
  
  def self.find_all_by_full_name(name)
    name.downcase!
    return [] if name.starts_with?('national -')
    query_string = "LOWER(admin_areas.name) = ?"
    admin_areas = self.find(:all, :conditions => [query_string] + [name])
    if admin_areas.empty?
      name_with_ampersand = name.gsub(' and ', ' & ')
      if name_with_ampersand != name
        admin_areas = self.find(:all, :conditions => [query_string] + [name_with_ampersand])
      else
        name_with_and = name.gsub(' & ', ' and ')
        if name_with_and != name
          admin_areas =  self.find(:all, :conditions => [query_string] + [name_with_and])
        end
      end
    end
    admin_areas
  end
  
end
