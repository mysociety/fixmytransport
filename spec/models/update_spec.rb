require 'spec_helper'

describe Update do
  before(:each) do
    @valid_attributes = {
      :problem_id => 1,
      :text => "value for text",
      :status_code => false,
      :confirmed_at => Time.now
    }
  end

end
