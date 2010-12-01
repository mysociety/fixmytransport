require 'spec_helper'

describe Update do
  
  describe 'when confirming' do 
    
    before do
      @update = Update.new(:text => 'test text', :reporter_name => 'Reporter Name')
      @update.status = :new
      @confirmation_time = Time.now - 5.days
      @update.confirmed_at = @confirmation_time
    end
    
    describe 'when the status is not new' do 
      
      before do 
        @update.status = :hidden
      end
      
      it 'should not change the status or set the confirmed time' do 
        @update.confirm!
        @update.status.should == :hidden
        @update.confirmed_at.should == @confirmation_time
      end
    
    end
    
    describe 'when the status is new' do 
      
      it 'should change the status to confirmed and set the confirmation time' do 
        @update.confirm!
        @update.status.should == :confirmed
        @update.confirmed_at.should > @confirmation_time
      end
      
    end
  
  end
  
end
