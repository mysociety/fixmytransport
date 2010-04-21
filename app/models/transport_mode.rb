# == Schema Information
# Schema version: 20100420165342
#
# Table name: transport_modes
#
#  id          :integer         not null, primary key
#  name        :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#  naptan_name :string(255)
#  active      :boolean
#

class TransportMode < ActiveRecord::Base
  has_many :transport_mode_stop_types
  has_many :stop_types, :through => :transport_mode_stop_types
  named_scope :active, :conditions => { :active => true }
end
