# == Schema Information
# Schema version: 20100707152350
#
# Table name: locality_links
#
#  id            :integer         not null, primary key
#  ancestor_id   :integer
#  descendant_id :integer
#  direct        :boolean
#  count         :integer
#  created_at    :datetime
#  updated_at    :datetime
#

require 'spec_helper'

describe LocalityLink do

  before do
    @link_class = LocalityLink
    @linked_class = Locality
    @ancestor = Locality.new
    @ancestor.stub!(:persistent_id).and_return(66)
    @descendant = Locality.new
    @descendant.stub!(:persistent_id).and_return(44)
    @default_attrs = {
      :ancestor => @ancestor,
      :descendant => @descendant,
      :direct => true
    }
    @model_type = LocalityLink
    @expected_identity_hash = { :direct => true,
                                :ancestor => { :persistent_id => 66 },
                                :descendant => { :persistent_id => 44 } }
    @expected_external_identity_fields = [:direct,
                                          {:ancestor => [:code, :name]},
                                          {:descendant => [:code, :name]}]
    @expected_identity_hash_populated = true
  end

  it_should_behave_like "an acts_as_dag model that exists in data generations and is versioned"

end
