# == Schema Information
# Schema version: 20100420165342
#
# Table name: stop_area_memberships
#
#  id                    :integer         not null, primary key
#  stop_id               :integer
#  stop_area_id          :integer
#  creation_datetime     :datetime
#  modification_datetime :datetime
#  revision_number       :integer
#  modification          :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#

class StopAreaMembership < ActiveRecord::Base
  belongs_to :stop_area
  belongs_to :stop
end
