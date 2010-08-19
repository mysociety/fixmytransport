require 'spec_helper'

describe ProblemMailer do
  
  describe 'when sending problem confirmations' do
 
    before do
      @problem = mock_model(Problem, :subject => "My Problem", 
                                     :description => "Some description")
      @recipient = mock_model(User, :email => "problemreporter@example.com", 
                                    :name => "Problem Reporter", 
                                    :anonymous? => false)
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
                                    :email => 'user@example.com', 
                                    :phone => '123',
                                    :anonymous? => false)
      @mock_problem = mock_model(Problem, :operator => @mock_operator, 
                                          :reporter => @mock_user,
                                          :subject => "Missing ticket machines", 
                                          :description => "Desperately need more.",
                                          :location => stops(:victoria_station_one))
    end
   
    describe "when creating a problem report" do

      it "should render successfully" do
        lambda { ProblemMailer.create_report(@mock_problem, [@mock_operator]) }.should_not raise_error
      end
      
    end
    
    describe 'when delivering a problem report' do 
    
      before do 
        @mailer = ProblemMailer.create_report(@mock_problem, [@mock_operator])
      end
      
      it 'should deliver successfully' do
        lambda { ProblemMailer.deliver(@mailer) }.should_not raise_error
      end
      
    end
    
  end
  
  describe 'when checking for a problem change' do 
  
    it 'should print a message if the council info for the problem location is different from that stored on the problem' do 
      mock_stop = mock_model(Stop, :council_info => "33|44")
      mock_problem = mock_model(Problem, :council_responsible? => true, 
                                         :council_info => "33,44",
                                         :location => mock_stop, 
                                         :id => 22)
      STDERR.should_receive(:puts).with("Councils changed for problem 22. Was 33,44, now 33|44")
      ProblemMailer.check_for_council_change(mock_problem)
    end
  
  end
  
  describe 'when sending problem reports' do 
    
    before do
      MySociety::MaPit.stub!(:call).and_return({ 22 => {'name' => 'Unemailable council'}, 
                                                 44 => {'name' => 'Emailable council'}})
      @emailable_council = mock_model(Council, :name => 'Emailable council')
      @unemailable_council = mock_model(Council, :name => 'Unemailable council')
      
      @operator_with_mail = mock_model(Operator, :email => 'operator@example.com', 
                                                 :name => "Emailable operator")
      @operator_without_mail = mock_model(Operator, :email => nil, 
                                                    :name => "Unemailable operator")
      @pte_with_mail = mock_model(PassengerTransportExecutive, :email => 'pte@example.com', 
                                                               :name => 'Emailable PTE')
      @pte_without_mail = mock_model(PassengerTransportExecutive, :email => nil, 
                                                                  :name => 'Unemailable PTE')
      @mock_problem_email_operator = mock_model(Problem, :responsible_organizations => [@operator_with_mail],
                                                         :emailable_organizations => [@operator_with_mail],
                                                         :unemailable_organizations => [],
                                                         :update_attribute => true)
      @mock_problem_no_email_operator = mock_model(Problem, :responsible_organizations => [@operator_without_mail],
                                                            :emailable_organizations => [],
                                                            :unemailable_organizations => [@operator_without_mail])
      @mock_problem_email_pte = mock_model(Problem, :responsible_organizations => [@pte_with_mail],
                                                    :emailable_organizations => [@pte_with_mail],
                                                    :unemailable_organizations => [],
                                                    :update_attribute => true)
      @mock_problem_no_email_pte = mock_model(Problem, :responsible_organizations => [@pte_without_mail],
                                                       :emailable_organizations => [],
                                                       :unemailable_organizations => [@pte_without_mail],
                                                       :update_attribute => true)
      @mock_problem_some_council_mails = mock_model(Problem, :responsible_organizations => [@emailable_council, 
                                                                                            @unemailable_council], 
                                                             :emailable_organizations => [@emailable_council],
                                                             :unemailable_organizations => [@unemailable_council],
                                                             :update_attribute => true)                    
      Problem.stub!(:sendable).and_return([@mock_problem_email_operator,
                                           @mock_problem_no_email_operator,
                                           @mock_problem_email_pte,
                                           @mock_problem_no_email_pte,
                                           @mock_problem_some_council_mails])
      
      ProblemMailer.stub!(:deliver_report)
      ProblemMailer.stub!(:check_for_council_change)
      STDERR.stub!(:puts)
    end
  
    it 'should ask for all sendable problems' do 
      Problem.should_receive(:sendable).and_return([@mock_problem_email_operator, 
                                                    @mock_problem_no_email_operator])
      ProblemMailer.send_reports
    end
    
    it 'should print a list of operators with missing emails' do 
      STDERR.should_receive(:puts).with("Unemailable operator")
      ProblemMailer.send_reports
    end
    
    it 'should print a list of PTEs with missing emails' do 
      STDERR.should_receive(:puts).with("Unemailable PTE")
      ProblemMailer.send_reports
    end
    
    it 'should print a list of councils with missing emails' do 
      STDERR.should_receive(:puts).with("Unemailable council")
      STDERR.should_not_receive(:puts).with("Emailable council")
      ProblemMailer.send_reports
    end
    
    it 'should send a report email for a problem which has an operator email' do
      ProblemMailer.should_receive(:deliver_report).with(@mock_problem_email_operator, [@operator_with_mail], [])
      ProblemMailer.send_reports
    end  
    
    it 'should send a report for a problem with a PTE with an email address' do 
      ProblemMailer.should_receive(:deliver_report).with(@mock_problem_email_pte, [@pte_with_mail], [])
      ProblemMailer.send_reports
    end
    
    it 'should send a report for a problem with councils with email addresses' do 
      Council.stub!(:from_hash).and_return(@unemailable_council)
      Council.stub!(:from_hash).with({ 'name' => 'Emailable council' }).and_return(@emailable_council)
      ProblemMailer.should_receive(:deliver_report).with(@mock_problem_some_council_mails, 
                                                         [@emailable_council], 
                                                         [@unemailable_council])
      ProblemMailer.send_reports
    end
    
    it 'should set the sent at time on each problem report delivered' do 
      @mock_problem_email_operator.should_receive(:update_attribute).with(:sent_at, anything)
      @mock_problem_email_pte.should_receive(:update_attribute).with(:sent_at, anything)
      ProblemMailer.send_reports
    end
    
    it 'should print the number of sent reports' do 
      STDERR.should_receive(:puts).with("Sent 3 reports")
      ProblemMailer.send_reports  
    end
    
    it 'should check for a change in the councils for the problem' do 
      ProblemMailer.should_receive(:check_for_council_change)
      ProblemMailer.send_reports
    end
    
  end
  
end
