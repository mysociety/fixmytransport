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
    @model_type = AdminArea
    @default_attrs = {}
  end

  it "should create a new instance given valid attributes" do
    AdminArea.create!(@valid_attributes)
  end

  it_should_behave_like "a model that exists in data generations"

  describe 'find all by name' do

    before do
      @admin_area = mock_model(AdminArea)
      AdminArea.stub!(:find).and_return([@admin_area])
    end

    it 'should not return admin areas starting with "National -"' do
      AdminArea.find_all_by_full_name('National - National Coach').should == []
    end

    it 'should find admin areas supplied with their region in a comma-delimited string' do
      expected_conditions = ["LOWER(admin_areas.name) = ? AND LOWER(regions.name) = ?", "warrington", "north west"]
      AdminArea.should_receive(:find).with(:all, :include => [:region],
                                                 :conditions => expected_conditions)
      AdminArea.find_all_by_full_name('Warrington, North West')
    end

    it 'should find areas regardless of usage of ampersands or ands' do
      expected_conditions = ["LOWER(admin_areas.name) = ?", 'tyne & wear']
      expected_substitute_conditions = ["LOWER(admin_areas.name) = ?", 'tyne and wear']
      AdminArea.should_receive(:find).with(:all, :include => [],
                                                 :conditions  => expected_conditions).and_return([])
      AdminArea.should_receive(:find).with(:all, :include => [],
                                                 :conditions => expected_substitute_conditions)
      AdminArea.find_all_by_full_name('Tyne & Wear')
    end

  end

end
