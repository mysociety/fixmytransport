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
    
    it 'should not allow the password set to be the same as the password of the associated user' do 
      user = User.new
      admin_user = AdminUser.new(:user => user)
      user.stub!(:valid_password?).with('sekrit').and_return(true)
      admin_user.password = 'sekrit'
      admin_user.password_confirmation = 'sekrit'
      admin_user.save.should == false
      admin_user.errors[:base].should == "You can't make your admin password the same as your main password"
    end
    
  end
end