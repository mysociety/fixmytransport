require 'spec_helper'

describe JourneyPattern do


  before(:each) do
    @valid_attributes = {
    }
    @model_type = JourneyPattern
    @default_attrs = {  }
  end

  it_should_behave_like "a model that exists in data generations"

  it_should_behave_like "a model that exists in data generations and is versioned"

end
