require 'spec_helper'

describe StopAreaLink do

  before do
    @link_class = StopAreaLink
    @linked_class = StopArea
    @ancestor = StopArea.new
    @ancestor.stub!(:persistent_id).and_return(66)
    @descendant = StopArea.new
    @descendant.stub!(:persistent_id).and_return(44)
    @default_attrs = {
      :direct => true,
      :ancestor => @ancestor,
      :descendant => @descendant
    }
    @model_type = StopAreaLink
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