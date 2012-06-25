require 'spec_helper'

describe CampaignMailer do

  describe 'when receiving mail' do

    before do
      filepath = File.join(RAILS_ROOT, 'spec', 'examples', 'email', "plain.txt")
      @raw_email = File.read(filepath)
      @mock_user = mock_model(User, :name_and_email => "Campaign Person <campaign.person@my-campaign.example.com>",
                                    :name => "Campaign Person")
      @mock_campaign = mock_model(Campaign, :get_recipient => @mock_user,
                                            :title => "A Test Campaign")
      @mock_message = mock_model(IncomingMessage)
      IncomingMessage.stub!(:create_from_mail).and_return(@mock_message)
    end

    describe 'if a campaign address can be found in the to: field' do

      before do
        Campaign.stub!(:find_by_campaign_email).with('campaign.person@my-campaign.example.com').and_return(@mock_campaign)
      end

      it 'should create an incoming message for the campaign from the mail' do
        IncomingMessage.should_receive(:create_from_mail).with(anything, @raw_email, @mock_campaign).and_return(@mock_message)
        CampaignMailer.receive(@raw_email)
      end

      it 'should send a message to the recipient telling them they have a message' do
        CampaignMailer.should_receive(:deliver_new_message).with(@mock_user, @mock_message, @mock_campaign)
        CampaignMailer.receive(@raw_email)
      end

    end

    describe 'if no campaign address can be found' do

      before do
        Campaign.stub!(:find_by_campaign_email).and_return(nil)
      end

      it 'should create an incoming message with no associated campaign' do
        IncomingMessage.should_receive(:create_from_mail).with(anything, @raw_email, nil)
        CampaignMailer.receive(@raw_email)
      end

      it 'should send a message to the contact address saying there is an unmatched incoming message' do
        CampaignMailer.should_receive(:deliver_unmatched_incoming_message)
        CampaignMailer.receive(@raw_email)
      end

    end

  end

  describe 'when sending a campaign update' do

    describe 'when not running in dry-run mode' do

      before do
        CampaignMailer.stub!(:dry_run).and_return(false)
        CampaignMailer.stub!(:sent_count).and_return(0)
        SentEmail.stub!(:find).and_return([])
        SentEmail.stub!(:create!)
        @mock_initiator = mock_model(User, :name => 'Initiator',
                                           :name_and_email => 'Initiator <initiator@example.com>',
                                           :email => 'initiator@example.com')
        @mock_user = mock_model(User, :email => 'supporter@example.com',
                                      :name => 'Supporter',
                                      :name_and_email => 'Supporter <supporter@example.com>')
        @mock_update_user = mock_model(User, :name => 'Update Sender',
                                             :first_name => 'Update')
        @mock_subscription = mock_model(Subscription, :user => @mock_user,
                                                      :token => 'mytoken')
        @mock_subscriptions = mock('subscription association', :confirmed => [@mock_subscription])
        @mock_campaign = mock_model(Campaign, :subscriptions => @mock_subscriptions,
                                              :title => "A test campaign",
                                              :description => 'Some description',
                                              :initiator => @mock_initiator)
        @mock_update = mock_model(CampaignUpdate, :campaign => @mock_campaign,
                                                  :user => @mock_update_user,
                                                  :update_attribute => true,
                                                  :incoming_message => nil,
                                                  :outgoing_message => nil,
                                                  :text => 'an update',
                                                  :is_advice_request? => false)
        @mock_comment = mock_model(Comment, :user => @mock_update_user,
                                            :user_name => @mock_update_user.name,
                                            :text => 'Some text',
                                            :update_attribute => true)
      end

      describe 'when sending emails about an update' do

        it 'should create a sent email model for each update email sent' do
          SentEmail.should_receive(:create!).with(:recipient => @mock_user,
                                                  :campaign => @mock_campaign,
                                                  :campaign_update => @mock_update)
          CampaignMailer.send_update(@mock_update, @mock_campaign)
        end

        it 'should send an advice request email and an expert advice request mail if the update is an advice request' do
          @mock_update.stub!(:is_advice_request?).and_return(true)
          ActionMailer::Base.deliveries.clear
          CampaignMailer.send_update(@mock_update, @mock_campaign)
          ActionMailer::Base.deliveries.size.should == 2
          expert_mail = ActionMailer::Base.deliveries.first
          expert_mail.body.should match(/Hello lovely transport boffins/)
          expert_mail.body.should match(/would like some advice/)
          expert_mail.body.should_not match(/stop receiving update/)

          supporter_mail = ActionMailer::Base.deliveries.second
          supporter_mail.body.should match(/Hi Supporter/)
          supporter_mail.body.should match(/would like some advice/)
          supporter_mail.body.should match(/stop receiving updates/)
        end

        it 'should not send an email to a recipient who has already received an email for this update' do
          mock_sent_email = mock_model(SentEmail, :recipient => @mock_user)
          SentEmail.stub!(:find).and_return([mock_sent_email])
          CampaignMailer.should_not_receive(:deliver_update)
          CampaignMailer.send_update(@mock_update, @mock_campaign)
        end

        it 'should not send an email to the person who created the update' do
          @mock_subscription.stub!(:user).and_return(@mock_update_user)
          CampaignMailer.should_not_receive(:deliver_update)
          CampaignMailer.send_update(@mock_update, @mock_campaign)
        end

      end

      describe 'when sending emails about a comment' do

        it 'should check for sent emails associated with the comment when sending updates about a comment' do
          SentEmail.should_receive(:find).with(:all, :conditions => ['comment_id = ?', @mock_comment])
          CampaignMailer.send_update(@mock_comment, @mock_campaign)
        end

      end

    end

  end

  def setup_write_to_other_data
    @campaign = mock_model(Campaign, :title => "Transport campaign")
    @user = mock_model(User, :name => 'Joe Campaign', :name_and_email => '')
    @expert = mock_model(User, :name => 'Bob Expert',
                               :first_name => 'Bob')
    @assignment = mock_model(Assignment, :campaign => @campaign,
                                         :user => @user,
                                         :creator => @expert,
                                         :data => {:name => 'Ken Transport'})
    @subject = "What you should do now"
  end

  describe "when creating a 'write-to-other' assignment" do

    before do
      setup_write_to_other_data
    end

    it "should render successfully" do
      lambda { CampaignMailer.create_write_to_other_assignment(@assignment, @subject) }.should_not raise_error
    end

  end

  describe "when delivering a 'write-to-other' assignment" do

    before do
      setup_write_to_other_data
      @mailer = CampaignMailer.create_write_to_other_assignment(@assignment, @subject)
    end

    it 'should deliver successfully' do
      lambda { CampaignMailer.deliver(@mailer) }.should_not raise_error
    end

  end

  describe 'when sending an outgoing message' do

    before do
      @user = mock_model(User, :name => "A test user")
      @mock_operator_contact = mock_model(OperatorContact)
      @mock_stop = mock_model(Stop, :name => 'A test stop',
                                    :atco_code => 'A test ATCO code',
                                    :plate_code => 'def',
                                    :naptan_code => nil,
                                    :landmark => nil,
                                    :street => nil,
                                    :crossing => nil,
                                    :indicator => nil,
                                    :bearing => nil,
                                    :easting => 444.44,
                                    :northing => 555.55,
                                    :persistent_id => 66,
                                    :transport_mode_names => ['Bus', 'Tram/Metro'])
      @mock_problem = mock_model(Problem, :recipient_contact => @mock_operator_contact,
                                          :sent_at => Time.now-1.day,
                                          :update_attribute => nil,
                                          :location => @mock_stop)
      @mock_operator = mock_model(Operator)
      @mock_campaign = mock_model(Campaign, :problem => @mock_problem)
      @mock_assignment = mock_model(Assignment, :problem => @mock_problem,
                                                :task_type_name => 'write-to-new-transport-organization',
                                                :organization => @mock_operator)
      @outgoing_message = mock_model(OutgoingMessage, :recipient_email => "recipient@example.com",
                                                      :recipient_cc => "cc@example.com",
                                                      :reply_name_and_email => 'reply@example.com',
                                                      :subject => 'A test subject',
                                                      :body => 'A test body',
                                                      :author => @user,
                                                      :assignment => @mock_assignment,
                                                      :campaign => @mock_campaign)
    end

    it 'should deliver successfully' do
      @mailer = CampaignMailer.create_outgoing_message(@outgoing_message)
      lambda { CampaignMailer.deliver(@mailer) }.should_not raise_error
    end

    describe 'when the outgoing message is in response to a "write-to-new-transport-organization" assignment' do

      describe 'if the problem has already been sent' do

        before do
          @mock_problem.stub!(:sent_at).and_return(Time.now-1.day)
        end

        it 'should not set the sent_at time on the problem' do
          @mock_problem.should_not_receive(:set_attribute).with(:sent_at, anything())
          CampaignMailer.send_outgoing_message(@outgoing_message)
        end


      end

      describe 'if the problem has not already been sent' do

        before do
          @mock_problem.stub!(:sent_at).and_return(nil)
        end

        it 'should set the sent_at time on the problem' do
          @mock_problem.should_receive(:update_attribute).with(:sent_at, anything())
          CampaignMailer.send_outgoing_message(@outgoing_message)
        end

      end

      it 'should add a sent email record for the organization contact and the problem the assignment is
          associated with' do
        SentEmail.should_receive(:create!).with(:recipient => @mock_operator_contact,
                                                :problem => @mock_problem)
        CampaignMailer.send_outgoing_message(@outgoing_message)
      end

    end

  end

end