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
end
