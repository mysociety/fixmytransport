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

require 'spec_helper'

describe AdminArea do
  before(:each) do
    @valid_attributes = {
      :code => "value for code",
      :atco_code => "value for atco_code",
      :short_name => "value for short_name",
      :country => "value for country",
      :region_id => "value for region_code",
      :national => false,
      :creation_datetime => Time.now,
      :modification_datetime => Time.now,
      :revision_number => "value for revision_number",
      :modification => "value for modification"
    }
  end

  it "should create a new instance given valid attributes" do
    AdminArea.create!(@valid_attributes)
  end
end
