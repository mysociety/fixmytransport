require 'spec_helper'

describe "home/index" do 
  
  it 'should not contain any spans with class "translation_missing"' do 
    render "home/index"
    response.should_not have_tag('span.translation_missing')
  end

end
