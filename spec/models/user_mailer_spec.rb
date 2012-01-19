require 'spec_helper'

describe UserMailer do

  before do
    @user = mock_model(User, :email => 'user@example.com',
                             :perishable_token => 'mytoken',
                             :name => 'User Name')
  end

  describe "when creating password reset instructions" do

    it "should render successfully" do
      lambda { UserMailer.create_password_reset_instructions(@user, nil, nil) }.should_not raise_error
    end

    describe 'if there is no post-login action' do

      it 'should set the subject of the email to "Reset your password"' do
        @mailer = UserMailer.create_password_reset_instructions(@user, nil, nil)
        @mailer.subject.should == 'FixMyTransport - Password reset instructions'
      end

    end

    describe 'when there is a post-login action of creating a problem' do

      before do
        @mock_problem = mock_model(Problem, :subject => "A test problem",
                                            :description => "A test description")
        @post_login_action_data = { :action => :create_problem }
      end

      it 'should set the subject of the email to "Confirm your problem"' do
        @mailer = UserMailer.create_password_reset_instructions(@user, @post_login_action_data, @mock_problem)
        @mailer.subject.should == 'FixMyTransport - Confirm your problem'
      end

      it 'should include the details of the problem in the body of the email' do
        @mailer = UserMailer.create_password_reset_instructions(@user, @post_login_action_data, @mock_problem)
        @mailer.body.should match(/Your problem report had the subject: A test problem/)
        @mailer.body.should match(/And description: A test description/)
      end

    end

  end

  describe 'when delivering password reset instructions' do

    before do
      @mailer = UserMailer.create_password_reset_instructions(@user, nil, nil)
    end

    it "should deliver successfully" do
      lambda { UserMailer.deliver(@mailer) }.should_not raise_error
    end

  end

  describe 'when creating a new account confirmation email' do

    it 'should render successfully' do
      lambda{ UserMailer.create_new_account_confirmation(@user, nil, nil) }.should_not raise_error
    end

    describe 'if there is no post-login action' do

      it 'should set the subject of the email to "Confirm your account"' do
        @mailer = UserMailer.create_new_account_confirmation(@user, nil, nil)
        @mailer.subject.should == 'FixMyTransport - Confirm your account'
      end

    end

    describe 'when there is a post-login action of creating a problem' do

      before do
        @mock_problem = mock_model(Problem, :subject => "A test problem",
                                            :description => "A test description")
        @post_login_action_data = { :action => :create_problem }
      end

      it 'should set the subject of the email to "Confirm your problem"' do
        @mailer = UserMailer.create_new_account_confirmation(@user, @post_login_action_data, @mock_problem)
        @mailer.subject.should == 'FixMyTransport - Confirm your problem'
      end

      it 'should include the details of the problem in the body of the email' do
        @mailer = UserMailer.create_new_account_confirmation(@user, @post_login_action_data, @mock_problem)
        @mailer.body.should match(/Your problem report had the subject: A test problem/)
        @mailer.body.should match(/And description: A test description/)
      end

    end

    describe 'when there is a post-login action of adding a campaign comment' do

      before do
        @mock_comment = mock_model(Comment, :text => "Some test text", :commented => mock_model(Campaign))
        @post_login_action_data = { :action => :add_comment }
      end

      it 'should set the subject of the email to "Confirm your comment"' do
        @mailer = UserMailer.create_new_account_confirmation(@user, @post_login_action_data, @mock_comment)
        @mailer.subject.should == 'FixMyTransport - Confirm your comment'
      end

      it 'should include the details of the comment in the body of the email' do
        @mailer = UserMailer.create_new_account_confirmation(@user, @post_login_action_data, @mock_comment)
        @mailer.body.should match(/Your comment reads: Some test text/)
      end

    end

    describe 'when there is a post-login action of adding a problem comment' do

      before do
        @mock_comment = mock_model(Comment, :text => "Some test text", :commented => mock_model(Problem))
        @post_login_action_data = { :action => :add_comment }
      end

      it 'should set the subject line of the email to "Confirm your update"' do
        @mailer = UserMailer.create_new_account_confirmation(@user, @post_login_action_data, @mock_comment)
        @mailer.subject.should == 'FixMyTransport - Confirm your update'
      end

      it 'should include the details of the comment in the body of the email, referred to as an update' do
        @mailer = UserMailer.create_new_account_confirmation(@user, @post_login_action_data, @mock_comment)
        @mailer.body.should match(/Your update reads: Some test text/)
      end

    end

  end

end
