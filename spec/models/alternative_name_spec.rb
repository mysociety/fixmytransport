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

require 'spec_helper'

describe AlternativeName do
  before(:each) do
    @valid_attributes = {
      :name => "value for name",
      :locality_id => 1,
      :short_name => "value for short_name",
      :qualifier_name => "value for qualifier_name",
      :qualifier_locality => "value for qualifier_locality",
      :qualifier_district => "value for qualifier_district",
      :creation_datetime => Time.now,
      :modification_datetime => Time.now,
      :revision_number => "value for revision_number",
      :modification => "value for modification"
    }
  end

  it "should create a new instance given valid attributes" do
    AlternativeName.create!(@valid_attributes)
  end
end
