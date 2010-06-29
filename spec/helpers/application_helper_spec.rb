require 'spec_helper'

describe ApplicationHelper do

  describe 'when creating search links' do 
  
    it 'should create links with URI-encoded search params' do 
      helper.external_search_link("some=& string").should == "http://www.google.co.uk/search?ie=UTF-8&q=some%3D%26+string"
    end
    
  end

end
