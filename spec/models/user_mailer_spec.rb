require 'spec_helper'

describe UserMailer do

  before do 
    @user = mock_model(User, :email => 'user@example.com', :perishable_token => 'mytoken')
  end

  describe "when creating password reset instructions" do

    it "should render successfully" do
      lambda { UserMailer.create_password_reset_instructions(@user) }.should_not raise_error
    end
    
  end

  describe 'when delivering password reset instructions' do 
  
    before do 
      @mailer = UserMailer.create_password_reset_instructions(@user)
    end

    it "should deliver successfully" do
      lambda { UserMailer.deliver(@mailer) }.should_not raise_error
    end

  end
  
end
