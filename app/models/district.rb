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

  def self.find_all_by_full_name(name)
    query_string = "LOWER(districts.name) = ?"
    includes = [:localities]
    districts = self.find(:all, :conditions => [query_string] + [name],
                                :include => includes)
    districts.select{ |district| ! district.localities.empty? }
  end

end
