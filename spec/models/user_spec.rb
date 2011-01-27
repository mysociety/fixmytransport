# == Schema Information
# Schema version: 20100707152350
#
# Table name: users
#
#  id                :integer         not null, primary key
#  name              :string(255)
#  email             :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  wants_fmt_updates :boolean
#

require 'spec_helper'

describe User do
  before(:each) do
    @valid_attributes = {
      :name => "value for name",
    }
  end

  describe 'when saving a registered user' do 
    
    before do 
      @user = User.new
      @user.email = 'test@example.com'
      @user.password = 'password'
      @user.password_confirmation = 'password'
      @user.registered = true
    end
    
    after do 
      user = User.find_by_email("test@example.com")
      user.destroy if user
    end
    
    it 'should not be valid if there is no user name' do 
      @user.valid?.should be_false
    end
    
    it 'should be valid if there is a name' do 
      @user.name = 'A Test Name'
      @user.valid?.should be_true
    end
    
    it 'should generate an email local part from the name' do 
      @user.name = 'A Test Name'
      @user.save
      @user.email_local_part.should == 'a.test.name'
    end
    
    it 'should remove non-ascii characters from the email local part' do 
      @user.name = "test$£%^&*()%'name"
      @user.save
      @user.email_local_part.should == 'testname'
    end
    
    
    it 'should generate the name "campaign" if there are no suitable characters in the name' do 
      @user.name = "$£%^&*()%'"
      @user.save
      @user.email_local_part.should == 'campaign'
    end
    
    it 'should not remove dots from the email local part' do 
      @user.name = "A.Test"
      @user.save
      @user.email_local_part.should == 'a.test'
    end
    
    it 'should not remove hyphens from the email local part' do 
      @user.name = 'A Test-Case'
      @user.save
      @user.email_local_part.should == 'a.test-case'
    end
    
    it 'should remove a leading dot or hyphen from the email local part' do 
      @user.name = '.A Test Case'
      @user.save
      @user.email_local_part.should == 'a.test.case'
    end
    
    it 'should remove a trailing dot or hyphen from the email local part' do 
      @user.name = 'A Test Case.'
      @user.save
      @user.email_local_part.should == 'a.test.case'
    end
    
    it 'should trim the local part to 64 characters' do 
      @user.name = 'S' * 65
      @user.save
      @user.email_local_part.should == 's' * 64
    end
    
  end

end
