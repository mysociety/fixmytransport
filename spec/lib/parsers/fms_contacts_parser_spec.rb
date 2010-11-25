require 'spec_helper'

describe Parsers::FmsContactsParser do 
  
  def example_file filename
    File.join(RAILS_ROOT, 'spec', 'examples', 'FixMyStreet', filename)
  end
  
  describe 'when parsing an example file of contacts data' do 
    
    before(:all) do 
      @parser = Parsers::FmsContactsParser.new
      @contacts = []
      @parser.parse_contacts(example_file("contacts.csv")){ |contact| @contacts << contact }
    end
  
    it 'should extract the area id' do 
      @contacts.first.area_id.should == 2267
    end
    
    it 'should extract the email adddress' do 
      @contacts.first.email.should == 'test@example.com'
    end
     
    it 'should extract the confirmed flag' do 
      @contacts.first.confirmed.should be_true
    end
    
    it 'should extract the category' do 
      @contacts.first.category.should == 'Other'
    end
    
    it 'should not load deleted rows' do 
      @contacts.size.should == 1
    end
    
    it 'should extract the notes' do 
      @contacts.first.notes.should == 'Note'
    end
      
  end
  
end
