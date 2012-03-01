# == Schema Information
# Schema version: 20100707152350
#
# Table name: localities
#
#  id                    :integer         not null, primary key
#  code                  :string(255)
#  name                  :text
#  short_name            :text
#  national              :boolean
#  creation_datetime     :datetime
#  modification_datetime :datetime
#  revision_number       :string(255)
#  modification          :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#  admin_area_id         :integer
#  qualifier_name        :string(255)
#  source_locality_type  :string(255)
#  grid_type             :string(255)
#  northing              :float
#  easting               :float
#  coords                :geometry
#  district_id           :integer
#  cached_slug           :string(255)
#

require 'spec_helper'

describe Locality do
  before(:each) do
    @valid_attributes = {
      :code => "value for code",
      :name => "value for name",
      :short_name => "value for short_name",
      :national => false,
      :creation_datetime => Time.now,
      :modification_datetime => Time.now,
      :revision_number => "value for revision_number",
      :modification => "value for modification"
    }
    @model_type = Locality
    @default_attrs = { :name => 'A test locality' }
  end

  it_should_behave_like "a model that is exists in data generations"

  it_should_behave_like "a model that is exists in data generations and has slugs"

  it "should create a new instance given valid attributes" do
    Locality.create!(@valid_attributes)
  end

  describe 'when finding by full name' do

    it 'should query for the name ignoring case' do
      Locality.should_receive(:find).with(:all, :order => 'localities.name asc',
                                                :conditions => ['LOWER(localities.name) = ?', 'london'],
                                                :include => [:admin_area, :district]).and_return([mock('result')])
      Locality.find_all_by_full_name('London')
    end


    describe 'when a name with and " and " is given and there are no results' do

      before do
        Locality.stub!(:find).with(:all, :order => 'localities.name asc',
                                         :conditions => ['LOWER(localities.name) = ?', 'upwood and the raveleys'],
                                         :include => [:admin_area, :district]).and_return([])
      end


      it 'should try a version with " & "' do
        Locality.should_receive(:find).with(:all, :order => 'localities.name asc',
                                            :conditions => ['LOWER(localities.name) = ?', 'upwood & the raveleys'],
                                            :include => [:admin_area, :district]).and_return([])
        Locality.find_all_by_full_name('Upwood and the Raveleys')
      end

    end

    describe 'when a name with a comma is given' do

      it 'should search for a locality with name and qualifier' do
        expected_conditions = ["LOWER(localities.name) = ? AND (LOWER(qualifier_name) = ?
                         OR LOWER(districts.name) = ?
                         OR LOWER(admin_areas.name) = ?)",
                         'euston', 'london', 'london', 'london']
        Locality.should_receive(:find).with(:all, :conditions => expected_conditions,
                                                  :include => [:admin_area, :district],
                                                  :order => 'localities.name asc').and_return([mock('result')])
        Locality.find_all_by_full_name('Euston, London')
      end
    end
  end
end
