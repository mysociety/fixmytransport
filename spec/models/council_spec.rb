require 'spec_helper'

describe Council do
  
  before do 
    @council = Council.from_hash({ 'id' => 22, 'name' => 'a test council' })
  end
  
  it 'should create an instance from a hash keyed by strings' do 
    @council.id.should == 22
    @council.name.should == 'a test council'
  end
  
  it 'should be able to respond to calls to emailable?' do 
    @council.emailable = true
    @council.emailable?.should be_true
    @council.emailable = false
    @council.emailable?.should be_false
  end
  
end
