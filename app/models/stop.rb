# == Schema Information
# Schema version: 20100408151525
#
# Table name: stops
#
#  id                         :integer         not null, primary key
#  atco_code                  :string(255)
#  naptan_code                :string(255)
#  plate_code                 :string(255)
#  common_name                :text
#  short_common_name          :text
#  landmark                   :text
#  street                     :text
#  crossing                   :text
#  indicator                  :text
#  bearing                    :string(255)
#  nptg_locality_code         :string(255)
#  locality_name              :string(255)
#  parent_locality_name       :string(255)
#  grand_parent_locality_name :string(255)
#  town                       :string(255)
#  suburb                     :string(255)
#  locality_centre            :boolean
#  grid_type                  :string(255)
#  easting                    :float
#  northing                   :float
#  lon                        :float
#  lat                        :float
#  stop_type                  :string(255)
#  bus_stop_type              :string(255)
#  administrative_area_code   :string(255)
#  creation_datetime          :datetime
#  modification_datetime      :datetime
#  revision_number            :integer
#  modification               :string(255)
#  status                     :string(255)
#  created_at                 :datetime
#  updated_at                 :datetime
#

class Stop < ActiveRecord::Base
  named_scope :active, :conditions => { :status => 'act' }
end
