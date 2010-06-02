# == Schema Information
# Schema version: 20100506162135
#
# Table name: localities
#
#  id                    :integer         not null, primary key
#  code                  :string(255)
#  atco_code             :string(255)
#  name                  :text
#  short_name            :text
#  country               :string(255)
#  region_code           :string(255)
#  national              :boolean
#  contact_email         :string(255)
#  contact_telephone     :string(255)
#  creation_datetime     :datetime
#  modification_datetime :datetime
#  revision_number       :string(255)
#  modification          :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#

class Locality < ActiveRecord::Base
  belongs_to :admin_area
  belongs_to :district
  has_dag_links :link_class_name => 'LocalityLink'
  has_many :stops, :order => 'common_name asc'
  
  def self.find_all_by_name(name)
    localities = find(:all, :conditions => ['lower(localities.name) = ? 
                                        or lower(admin_areas.name) = ? 
                                        or lower(districts.name) = ?
                                        or lower(regions.name) = ?', 
                                        name.downcase, name.downcase, name.downcase, name.downcase],
                       :include => [{:admin_area => :region}, :district])
    localities
  end
  
  def self.find_all_with_descendants(name)
    localities = find_all_by_name(name)
    with_descendants = localities.map{ |locality| [locality, locality.descendants] }.flatten.uniq
  end
  
end
