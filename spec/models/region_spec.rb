# == Schema Information
# Schema version: 20100707152350
#
# Table name: regions
#
#  id                    :integer         not null, primary key
#  code                  :string(255)
#  name                  :text
#  creation_datetime     :datetime
#  modification_datetime :datetime
#  revision_number       :string(255)
#  modification          :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#  cached_slug           :string(255)
#

require 'spec_helper'

describe Region do
  before(:each) do
    @valid_attributes = {
      :code => "value for code",
      :name => "value for name",
      :creation_datetime => Time.now,
      :modification_datetime => Time.now,
      :revision_number => "value for revision_number",
      :modification => "value for modification"
    }
    @model_type = Region
  end

  it_should_behave_like "a model that is exists in data generations"
  
  it_should_behave_like "a model that is exists in data generations and has slugs"

  it "should create a new instance given valid attributes" do
    Region.create!(@valid_attributes)
  end
end
