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
  
  describe 'when handling an external auth token' do 
    
    describe 'when getting facebook data' do

      before do 
        @mock_io = mock('IO stream', :read => "")
        JSON.stub!(:parse)
        User.stub!(:open).and_return(@mock_io)
      end
      
      it 'should make a call to the facebook graph URL, passing the access token' do 
        User.should_receive(:open).with("https://graph.facebook.com/me?access_token=mytoken").and_return(@mock_io)
        User.get_facebook_data('mytoken')
      end

      it 'should parse the response as JSON' do
        JSON.should_receive(:parse)
        User.get_facebook_data('mytoken')
      end
        
    end

    describe 'when the source is facebook' do       
      
      before do 
        @mock_user = mock_model(User, :save! => true, 
                                      :access_tokens => [])
        @mock_user.access_tokens.stub!(:build).and_return(true)
        User.stub!(:new).and_return(@mock_user)
        User.stub!(:get_facebook_data).and_return({'id' => 'myfbid',
                                                   'name' => 'Test Name', 
                                                   'email' => 'test@example.com'})
      end
      
      it 'should look up user records by the facebook ID' do 
        AccessToken.should_receive(:find).with(:first, :conditions => ['key = ? and token_type = ?', 'myfbid', 'facebook'])
        User.handle_external_auth_token('mytoken', 'facebook')
      end
      
      
    end
    
  end

end
