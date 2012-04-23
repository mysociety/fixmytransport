require 'spec_helper'

describe SentEmail do

  describe 'when creating instances' do 
    
    before do 
      @recipient = OperatorContact.new(:category => 'Other', 
                                       :operator_id => 1,
                                       :email => 'test@example.com')
    end
    
    it 'should set the recipient so that it can subsequently be retrieved' do 
      @recipient.save!
      @sent_email = SentEmail.create!(:recipient => @recipient)
      @found_email = SentEmail.find(@sent_email.id)
      @found_email.recipient.should == @recipient
    end
    
    describe 'when the recipient belongs to a previous data generation' do 
      
      before do 
        @recipient.generation_low = PREVIOUS_GENERATION
        @recipient.generation_high = PREVIOUS_GENERATION
        @recipient.save!
      end
      
      it 'should return the successor to a recipient if the recipient belongs to a previous data generation' do 
        @successor = OperatorContact.create!(:category => 'Other',
                                             :operator_id => 1,
                                             :email => 'test@example.com',
                                             :previous_id => @recipient.id)
        @sent_email = SentEmail.create!(:recipient => @recipient)
        @found_email = SentEmail.find(@sent_email.id)
        @found_email.recipient.should == @successor
      end
    
      it 'should raise an error if no successor can be found for a recipient belonging to a previous generation' do 
        @sent_email = SentEmail.create!(:recipient => @recipient)
        @found_email = SentEmail.find(@sent_email.id)
        lambda{ @found_email.recipient }.should raise_error("No recipient for sent_email #{@sent_email.id}")
      end
      
    end

    after do 
      @recipient.destroy
      @sent_email.destroy
      @successor.destroy if @successor
    end
        
  end

end