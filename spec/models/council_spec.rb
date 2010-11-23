require 'spec_helper'

describe Council do
  
  before do 
    @council = Council.from_hash({ 'id' => 22, 'name' => 'A Test Council' })
  end
  
  it 'should create an instance from a hash keyed by strings' do 
    @council.id.should == 22
    @council.name.should == 'A Test Council'
  end
  
  it 'should be able to respond to calls to emailable?' do 
    @council.emailable = true
    @council.emailable?.should be_true
    @council.emailable = false
    @council.emailable?.should be_false
  end
  
  describe 'when asked for a contact for a problem category' do 
  
    before do 
      @other_contact = mock_model(CouncilContact, :category => 'Other',
                                                  :email => 'other@example.com')
      @unrelated_contact = mock_model(CouncilContact, :category => 'Unrelated', 
                                                      :email => 'unrelated@example.com')
      @category_contact = mock_model(CouncilContact, :category => 'Test category', 
                                                     :email => 'test@example.com')
    end
  
    it 'should return the contact for the contact for the category if there is one' do 
      CouncilContact.stub!(:find).and_return([@unrelated_contact, @category_contact, @other_contact])
      @council.contact_for_category('Test category').should == @category_contact
    end
    
    it 'should return the contact for the contact for category "other" if there is no contact for the category passed' do 
      CouncilContact.stub!(:find).and_return([@unrelated_contact, @other_contact])
      @council.contact_for_category('Test category').should == @other_contact
    end
    
    it 'should raise an error if there is no contact for the category or for "other"' do 
      CouncilContact.stub!(:find).and_return([@unrelated_contact])
      lambda{ @council.contact_for_category('Test category') }.should raise_error('No "Other" category contact for A Test Council (area ID: 22)')
    end
    
  end
  
end
