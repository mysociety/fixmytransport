# == Schema Information
# Schema version: 20100707152350
#
# Table name: regions
#
#  id                    :integer         not null, primary key
#  code                  :string(255)
#  name                  :text
#  creation_datetime     :datetime
#  modification_datetime :datetime
#  revision_number       :string(255)
#  modification          :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#  cached_slug           :string(255)
#

class Region < ActiveRecord::Base
  has_friendly_id :name, :use_slug => true
  has_many :admin_areas
  has_many :localities, :through => :admin_areas
  
  # instance methods
  def full_name
    "#{name} region" 
  end
  
  # class methods
  def self.find_all_by_full_name(name)
    name = name.downcase
    name = name.gsub(/ region$/, '')
    find(:all, :conditions => ["LOWER(name) = ?", name])
  end
  
end
