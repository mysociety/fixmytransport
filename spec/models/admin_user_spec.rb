require 'spec_helper'

describe AdminUser do
  
  describe 'when finding by login' do
    
    before do 
      @mock_user = mock_model(User)
      @mock_admin_user = mock_model(AdminUser)
    end
    
    it "should return nil if there is a user with that email but they don't have an admin user record" do 
      User.stub!(:find).with(:first, :conditions => ['email = ?', 'test@example.com']).and_return(@mock_user)
      @mock_user.stub!(:admin_user).and_return(nil)
      AdminUser.find_by_login('test@example.com').should == nil
    end
    
    it "should return the admin user associated with a user with that email if there is one" do 
      User.stub!(:find).with(:first, :conditions => ['email = ?', 'test@example.com']).and_return(@mock_user)
      @mock_user.stub!(:admin_user).and_return(@mock_admin_user)
      AdminUser.find_by_login('test@example.com').should == @mock_admin_user
    end
    
    it 'should return nil if there is no user with that email address' do 
      User.stub!(:find).with(:first, :conditions => ['email = ?', 'test@example.com']).and_return(nil)
      AdminUser.find_by_login('test@example.com').should == nil
    end
    
  end
  
  describe 'when validating' do 
    
    def expect_bad_format_error(password)
      user = User.new
      admin_user = AdminUser.new(:user => user)
      admin_user.password = password
      admin_user.password_confirmation = password
      admin_user.save.should == false
      admin_user.errors[:password].should == 'Please enter a password that is at least 8 characters with a mix of upper and lowercase letters and numbers or punctuation'
    end
    
    it 'should not allow the password set to be the same as the password of the associated user' do 
      user = User.new
      admin_user = AdminUser.new(:user => user)
      user.stub!(:valid_password?).with('sekrit').and_return(true)
      admin_user.password = 'sekrit'
      admin_user.password_confirmation = 'sekrit'
      admin_user.save.should == false
      admin_user.errors[:base].should == "You can't make your admin password the same as your main password"
    end
    
    it 'should not allow a lowercase only password' do 
      expect_bad_format_error('oooooooo')
    end
    it 'should not allow a password of less than eight characters' do 
      expect_bad_format_error('1sO')
    end
    
    it 'should not allow an uppercase only password' do 
      expect_bad_format_error('OOOOOOOO')
    end
    
    it 'should not allow a numbers only password' do
      expect_bad_format_error('12345678')
    end
    
    it 'should allow a password with a mix of upper and lower case and numbers or punctuation' do 
      user = User.new
      admin_user = AdminUser.new(:user => user)
      admin_user.password = '1rEsorD?'
      admin_user.password_confirmation = '1rEsorD?'
      admin_user.valid?.should == true
    end
    
  end
end