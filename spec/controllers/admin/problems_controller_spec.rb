require 'spec_helper'

describe Admin::ProblemsController do

  describe 'GET #show' do

    before do
      @default_params = { :id => 55 }
      @required_admin_permission = :issues
    end

    def make_request(params=@default_params)
      get :show, params
    end

    it_should_behave_like "an action that requires an admin user"

    it_should_behave_like "an action that requires a specific admin permission"


  end

  describe 'POST #resend' do

    def make_request
      post :resend, { :id => 55, :responsibility_id => 66 }
    end

    before do
      @operator =  mock_model(Operator)
      @responsibility = mock_model(Responsibility, :organization =>@operator)
      @responsibilities = mock('responsibilities', :find => @responsibility)
      @problem = mock_model(Problem, :responsibilities => @responsibilities,
                                     :campaign => nil)
      Problem.stub!(:find).and_return(@problem)
      @sent_email = mock_model(SentEmail)
      ProblemMailer.stub!(:send_report).and_return([@sent_email])
      @required_admin_permission = :issues
    end

    it_should_behave_like "an action that requires a specific admin permission"

    it 'should look for the problem by id' do
      Problem.should_receive(:find).with('55')
      make_request
    end

    it 'should look for the problem responsibility by id' do
      @problem.responsibilities.should_receive(:find).with('66')
      make_request
    end

    it 'should resend the problem to the responsible organization' do
      ProblemMailer.should_receive(:send_report).with(@problem, [@operator], [])
      make_request
    end

    describe 'if the problem has a campaign' do

      before do
        @problem.stub!(:campaign).and_return(mock_model(Campaign, :campaign_events => []))
        @controller.stub!(:user_for_edits).and_return('admin user')
      end

      it 'should add a problem_resent campaign event to the campaign' do
        @problem.campaign.campaign_events.should_receive(:create!).with(:event_type => 'problem_report_resent',
                                                                        :data => {:user => 'admin user',
                                                                                  :sent_emails => [@sent_email.id]})
        make_request
      end

    end

  end

end