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
  has_friendly_id :slug_name, :use_slug => true
  
  def slug_name
    return short_name if short_name 
    return name
  end
end
