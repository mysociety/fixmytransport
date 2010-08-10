require 'spec_helper'

describe ProblemMailer do
  
  describe 'when sending problem confirmations' do
 
    before do
      @problem = mock_model(Problem, :subject => "My Problem", 
                                     :description => "Some description")
      @recipient = mock_model(User, :email => "problemreporter@example.com", 
                                    :name => "Problem Reporter")
      @token = "test-token"
    end
  
    describe "when creating a problem confirmation" do

      it "should render successfully" do
        lambda { ProblemMailer.create_problem_confirmation(@recipient, @problem, @token) }.should_not raise_error
      end
      
    end
  
    describe 'when delivering a problem confirmation' do 
    
      before do 
        @mailer = ProblemMailer.create_problem_confirmation(@recipient, @problem, @token)
      end

      it "should deliver successfully" do
        lambda { ProblemMailer.deliver(@mailer) }.should_not raise_error
      end

    end
    
  end
  
  describe 'when sending problem reports' do 
    
    before do
      @mock_operator = mock_model(Operator, :email => 'operator@example.com', 
                                            :name => 'Test Operator')
      @mock_user = mock_model(User, :name => 'Test User', 
                                    :email => 'user@example.com')
      @mock_problem = mock_model(Problem, :operator => @mock_operator, 
                                          :reporter => @mock_user,
                                          :subject => "Missing ticket machines", 
                                          :description => "Desperately need more.",
                                          :location => stops(:victoria_station_one))
    end
   
    describe "when creating a problem report" do

      it "should render successfully" do
        lambda { ProblemMailer.create_report(@mock_problem) }.should_not raise_error
      end
      
    end
    
    describe 'when delivering a problem report' do 
    
      before do 
        @mailer = ProblemMailer.create_report(@mock_problem)
      end
      
      it 'should deliver successfully' do
        lambda { ProblemMailer.deliver(@mailer) }.should_not raise_error
      end
      
    end
    
  end
  
  describe 'when sending problem reports' do 
    
    before do
      @operator_with_mail = mock_model(Operator, :email => 'operator@example.com', 
                                                 :name => "Emailable operator")
      @operator_without_mail = mock_model(Operator, :email => nil, 
                                                    :name => "Unemailable operator")
      @mock_problem_one = mock_model(Problem, :operator => @operator_with_mail)
      @mock_problem_two = mock_model(Problem, :operator => @operator_without_mail)
      Problem.stub!(:sendable).and_return([@mock_problem_one, @mock_problem_two])
      ProblemMailer.stub!(:deliver_report)
      STDERR.stub!(:puts)
    end
  
    it 'should ask for all sendable problems' do 
      Problem.should_receive(:sendable).and_return([@mock_problem_one, @mock_problem_two])
      ProblemMailer.send_reports
    end
    
    it 'should print a list of operators with missing emails' do 
      STDERR.should_receive(:puts).with("Unemailable operator")
      ProblemMailer.send_reports
    end
    
    it 'should send a report email for a problem which has an operator email' do
      ProblemMailer.should_receive(:deliver_report).with(@mock_problem_one)
      ProblemMailer.send_reports
    end  
    
  end
  
end
