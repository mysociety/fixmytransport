require 'spec_helper'

describe QuestionnaireMailer do
  
  describe 'when sending questionnaires' do 
  
    before do 
      @suspended_user = mock_model(User, :suspended? => true, 
                                         :is_hidden? => false)
      @hidden_user = mock_model(User, :is_hidden? => true,
                                      :suspended? => false)
      @user = mock_model(User, :suspended? => false,
                               :is_hidden? => false)
      @questionnaire = mock_model(Questionnaire)
      @problem = mock_model(Problem, :questionnaires => mock('questionnaire', :create! => @questionnaire),
                                     :send_questionnaire= => nil,
                                     :update_attribute => nil,
                                     :subject => 'my test subject')
      Problem.stub!(:needing_questionnaire).and_return([@problem])
      Campaign.stub!(:needing_questionnaire).and_return([])
      QuestionnaireMailer.stub!(:deliver_questionnaire)
    end
    
    it 'should not send a questionnaire to a user who is suspended' do 
      @problem.stub!(:reporter).and_return(@suspended_user)
      QuestionnaireMailer.should_not_receive(:deliver_questionnaire).with(@problem, @questionnaire)
      QuestionnaireMailer.send_questionnaires
    end
    
    it 'should not send a questionnaire to a user who is hidden' do 
      @problem.stub!(:reporter).and_return(@suspended_user)
      QuestionnaireMailer.should_not_receive(:deliver_questionnaire).with(@problem, @questionnaire)
      QuestionnaireMailer.send_questionnaires
    end
    
    it 'should send a questionnaire to a user who is not suspended or hidden' do 
      @problem.stub!(:reporter).and_return(@user)
      QuestionnaireMailer.should_receive(:deliver_questionnaire).with(@problem, @questionnaire, @user, "my test subject")
      QuestionnaireMailer.send_questionnaires
    end
      
    it 'should set the send_questionnaire flag on the problem to false' do
      @problem.stub!(:reporter).and_return(@user)
      @problem.should_receive(:update_attribute).with('send_questionnaire', false)
      QuestionnaireMailer.send_questionnaires
    end
      
  end
  
  describe "when creating a questionnaire" do
    
    before do 
      @user = mock_model(User, :name => 'Test User',
                               :name_and_email => 'test@example.com')
      @campaign = mock_model(Campaign, :description => 'test description',
                                       :confirmed_at => Time.now - 1.day)
      @questionnaire = mock_model(Questionnaire, :token => 'mytoken')
    end

    it "should render successfully" do
      lambda { QuestionnaireMailer.create_questionnaire(@campaign, @questionnaire, @user, 'test title') }.should_not raise_error
    end

  end

  describe 'when delivering a questionnaire' do
    
    before do 
      @user = mock_model(User, :name => 'Test User',
                               :name_and_email => 'test@example.com')
      @campaign = mock_model(Campaign, :description => 'test description',
                                       :confirmed_at => Time.now - 1.day)
      @questionnaire = mock_model(Questionnaire, :token => 'mytoken')
    end
    
    before do
      @mailer = QuestionnaireMailer.create_questionnaire(@campaign, @questionnaire, @user, 'test title')
    end

    it 'should deliver successfully' do
      lambda { QuestionnaireMailer.deliver(@mailer) }.should_not raise_error
    end

  end

end