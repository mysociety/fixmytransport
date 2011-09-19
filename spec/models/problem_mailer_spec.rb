require 'spec_helper'

describe ProblemMailer do

  before do
    @mock_stop = mock_model(Stop, :name => 'A test stop',
                                  :atco_code => 'abc',
                                  :plate_code => 'def',
                                  :naptan_code => nil,
                                  :landmark => nil,
                                  :street => nil,
                                  :crossing => nil,
                                  :indicator => nil,
                                  :bearing => nil,
                                  :easting => 444.44,
                                  :northing => 555.55,
                                  :transport_mode_names => ['Bus', 'Tram/Metro'])
  end

  describe 'when sending problem reports' do

    before do
      @mock_contact = mock_model(OperatorContact, :email => 'operator@example.com')
      @mock_operator = mock_model(Operator, :contact_for_category_and_location => @mock_contact,
                                            :name => 'Test Operator')
      @mock_user = mock_model(User, :email => 'user@example.com')
      @mock_problem = mock_model(Problem, :operator => @mock_operator,
                                          :recipient_contact => @mock_contact, 
                                          :recipient_emails => { :email => @mock_contact.email },
                                          :reporter => @mock_user,
                                          :reporter_name => 'Test User',
                                          :reporter_phone => '123',
                                          :reply_email => @mock_user.email,
                                          :reply_name_and_email => "Test User <#{@mock_user.email}>",
                                          :campaign => nil,
                                          :category => 'Other',
                                          :subject => "Missing ticket machines",
                                          :description => "Desperately need more.",
                                          :emailable_organizations => [@mock_operator],
                                          :location => @mock_stop)
    end

    describe "when creating a problem report" do

      it "should render successfully" do
        lambda { ProblemMailer.create_report(@mock_problem, @mock_operator, [@mock_operator]) }.should_not raise_error
      end

    end

    describe 'when delivering a problem report' do

      before do
        @mailer = ProblemMailer.create_report(@mock_problem, @mock_operator, [@mock_operator])
      end

      it 'should deliver successfully' do
        lambda { ProblemMailer.deliver(@mailer) }.should_not raise_error
      end

    end

  end

  describe 'when sending a comment' do

    before do
      @mock_subscriber = mock_model(User, :name_and_email => 'Subscriber <subscriber@example.com>',
                                          :name => 'Subscriber')
      @mock_commenter = mock_model(User, :name => 'Commenter')
      @mock_subscription = mock_model(Subscription, :user => @mock_subscriber,
                                                    :token => 'mytoken')
      @mock_problem = mock_model(Problem, :subscriptions => [],
                                          :subject => 'A test subject')
      @mock_comment = mock_model(Comment, :commented => @mock_problem,
                                          :user => @mock_commenter,
                                          :user_name => @mock_commenter.name,
                                          :update_attribute => true,
                                          :mark_fixed => false,
                                          :text => 'A test comment')
      @mock_problem.subscriptions.stub!(:confirmed).and_return([@mock_subscription])
      SentEmail.stub!(:find).and_return([])
    end

    it 'should check for sent emails associated with the comment' do
      SentEmail.should_receive(:find).with(:all, :conditions => ['comment_id = ?', @mock_comment]).and_return([])
      ProblemMailer.send_comment(@mock_comment, @mock_problem)
    end

    it 'should not send an email to a recipient who has already received an email for this comment' do
      mock_sent_email = mock_model(SentEmail, :recipient => @mock_subscriber)
      SentEmail.stub!(:find).and_return([mock_sent_email])
      ProblemMailer.should_not_receive(:deliver_comment)
      ProblemMailer.send_comment(@mock_comment, @mock_problem)
    end

    it 'should not send an email to the person who created the comment' do
      @mock_problem.stub!(:subscriptions).and_return([])
      @mock_problem.subscriptions.stub!(:confirmed).and_return([mock_model(Subscription, :user => @mock_commenter)])      
      ProblemMailer.should_not_receive(:deliver_comment)
      ProblemMailer.send_comment(@mock_comment, @mock_problem)
    end

    it 'should create a sent email model for each comment email sent' do
      SentEmail.should_receive(:create!).with(:recipient => @mock_subscriber,
                                              :problem => @mock_problem,
                                              :comment => @mock_comment)
      ProblemMailer.send_comment(@mock_comment, @mock_problem)
    end

    it 'should deliver an email to each problem subscriber' do
      ProblemMailer.should_receive(:deliver_comment).with(@mock_subscriber, @mock_comment, @mock_subscription)
      ProblemMailer.send_comment(@mock_comment, @mock_problem)
    end

    it 'should set the sent_at attribute on the comment' do
      @mock_comment.should_receive(:update_attribute).with(:sent_at, anything())
      ProblemMailer.send_comment(@mock_comment, @mock_problem)
    end

  end

  describe 'when sending problem reports' do

    def make_mock_problem(emailable_orgs, unemailable_orgs, contact, contact_emails)
      mock_model(Problem, :responsible_organizations => emailable_orgs + unemailable_orgs,
                          :emailable_organizations => emailable_orgs,
                          :unemailable_organizations => unemailable_orgs,
                          :recipient_contact => contact,
                          :recipient_emails => contact_emails,
                          :update_attribute => true,
                          :reply_email => @reporter.email,
                          :reply_name_and_email => "Test User <#{@reporter.email}>",
                          :reporter_name => 'Test User',
                          :reporter_phone => '123',
                          :subject => 'A test problem',
                          :description => 'Some description',
                          :reporter => @reporter,
                          :category => 'Other',
                          :location => @mock_stop,
                          :location_type => 'Stop',
                          :location_id => @mock_stop.id,
                          :time => nil,
                          :date => nil,
                          :campaign => nil)
    end

    before do
      @reporter = mock_model(User, :name => "John Q User",
                                   :email => 'john@example.com',
                                   :phone => nil)
      MySociety::Config.stub!(:getbool).with("STAGING_SITE", true).and_return(false)
      MySociety::Config.stub!(:getbool).with("SITE_VISIBLE", true).and_return(true)
      MySociety::MaPit.stub!(:call).and_return({ 22 => {'name' => 'Unemailable council'},
                                                 44 => {'name' => 'Emailable council'}})

      @emailable_council = mock_model(Council, :name => 'Emailable council')
      @council_contact = mock_model(CouncilContact, :email => 'council@example.com')

      @unemailable_council = mock_model(Council, :name => 'Unemailable council')

      @operator_with_mail = mock_model(Operator, :name => "Emailable operator")
      @operator_contact = mock_model(OperatorContact, :email => 'operator@example.com')

      @operator_without_mail = mock_model(Operator, :name => "Unemailable operator")

      @pte_with_mail = mock_model(PassengerTransportExecutive, :name => 'Emailable PTE')
      @pte_contact = mock_model(PassengerTransportExecutiveContact, :email => 'pte@example.com')
      @pte_without_mail = mock_model(PassengerTransportExecutive, :name => 'Unemailable PTE')

      @mock_problem_email_operator = make_mock_problem([@operator_with_mail], 
                                                       [], 
                                                       @operator_contact, 
                                                       { :email => @operator_contact.email })
      @mock_problem_no_email_operator = make_mock_problem([], 
                                                          [@operator_without_mail], 
                                                          nil, 
                                                          nil)
      @mock_problem_email_pte =  make_mock_problem([@pte_with_mail], 
                                                   [], 
                                                   @pte_contact, 
                                                   { :email => @pte_contact.email })
      @mock_problem_no_email_pte = make_mock_problem([], 
                                                     [@pte_without_mail], 
                                                     nil,
                                                     nil)
      @mock_problem_some_council_mails = make_mock_problem([@emailable_council], 
                                                           [@unemailable_council], 
                                                           @council_contact, 
                                                           { :email => @council_contact.email })
      @mock_problem_no_orgs = make_mock_problem([],[], nil, nil)

      @sendable = [@mock_problem_email_operator,
                   @mock_problem_email_pte,
                   @mock_problem_some_council_mails]
      @unsendable = [@mock_problem_no_email_operator,
                     @mock_problem_no_email_pte]
      @all = @sendable + @unsendable
      Problem.stub!(:sendable).and_return([@mock_problem_email_operator,
                                           @mock_problem_no_email_operator,
                                           @mock_problem_email_pte,
                                           @mock_problem_no_email_pte,
                                           @mock_problem_some_council_mails])

      Problem.stub!(:unsendable).and_return([@mock_problem_no_orgs])
      Stop.stub!(:find).with(@mock_stop.id).and_return(@mock_stop)
      ProblemMailer.stub!(:deliver_report)
      SentEmail.stub!(:create!)
      STDERR.stub!(:puts)
    end

    it 'should ask for all sendable problems' do
      Problem.should_receive(:sendable).and_return([@mock_problem_email_operator,
                                                    @mock_problem_no_email_operator])
      ProblemMailer.send_reports
    end

    describe 'when being verbose' do

      it 'should print a list of operators with missing emails' do
        STDERR.should_receive(:puts).with("Unemailable operator")
        ProblemMailer.send_reports(dryrun=false, verbose=true)
      end

      it 'should print a list of PTEs with missing emails' do
        STDERR.should_receive(:puts).with("Unemailable PTE")
        ProblemMailer.send_reports(dryrun=false, verbose=true)
      end

      it 'should print a list of councils with missing emails' do
        STDERR.should_receive(:puts).with("Unemailable council")
        STDERR.should_not_receive(:puts).with("Emailable council")
        ProblemMailer.send_reports(dryrun=false, verbose=true)
      end

    end

    it 'should send a report email for a problem which has an operator email' do
      ProblemMailer.should_receive(:deliver_report).with(@mock_problem_email_operator, @operator_with_mail, [@operator_with_mail], [])
      ProblemMailer.send_reports
    end

    it 'should send a report for a problem with a PTE with an email address' do
      ProblemMailer.should_receive(:deliver_report).with(@mock_problem_email_pte, @pte_with_mail, [@pte_with_mail], [])
      ProblemMailer.send_reports
    end

    it 'should send a report for a problem with councils with email addresses' do
      Council.stub!(:from_hash).and_return(@unemailable_council)
      Council.stub!(:from_hash).with({ 'name' => 'Emailable council' }).and_return(@emailable_council)
      ProblemMailer.should_receive(:deliver_report).with(@mock_problem_some_council_mails,
                                                         @emailable_council,
                                                         [@emailable_council],
                                                         [@unemailable_council])
      ProblemMailer.send_reports
    end

    it 'should create a sent email record for each problem report delivered' do
      SentEmail.should_receive(:create!).with(:problem => @mock_problem_email_operator,
                                              :recipient => @operator_contact)
      SentEmail.should_receive(:create!).with(:problem => @mock_problem_email_pte,
                                              :recipient => @pte_contact)
      ProblemMailer.send_reports
    end

    it 'should set the "sent at" time on each problem report delivered' do
      @mock_problem_email_operator.should_receive(:update_attribute).with(:sent_at, anything)
      @mock_problem_email_pte.should_receive(:update_attribute).with(:sent_at, anything)
      ProblemMailer.send_reports
    end

    it 'should print the number of sent reports' do
      STDERR.should_receive(:puts).with("Sent #{@sendable.size} reports")
      ProblemMailer.send_reports
    end

    describe 'when in dryrun mode' do

      it 'should print output for each message that would be sent' do
        STDERR.should_receive(:puts).with("Would send the following:").exactly(@sendable.size).times
        ProblemMailer.send_reports(dryrun=true)
      end

      it 'should not send messages' do
        ProblemMailer.should_not_receive(:deliver_report)
        ProblemMailer.send_reports(dryrun=true)
      end

      it 'should not update message attributes' do
        @all.each do |problem|
          problem.should_not_receive(:update_attribute)
        end
        ProblemMailer.send_reports(dryrun=true)
      end

    end
  end

end
