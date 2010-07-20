# == Schema Information
# Schema version: 20100707152350
#
# Table name: alternative_names
#
#  id                    :integer         not null, primary key
#  name                  :text
#  locality_id           :integer
#  short_name            :text
#  qualifier_name        :text
#  qualifier_locality    :text
#  qualifier_district    :text
#  creation_datetime     :datetime
#  modification_datetime :datetime
#  revision_number       :string(255)
#  modification          :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#

class AlternativeName < ActiveRecord::Base
  belongs_to :locality
end
