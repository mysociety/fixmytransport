require 'spec_helper'

describe Admin::ProblemsController do

  describe 'POST #resend' do 
    
    def make_request
      post :resend, { :id => 55 }
    end
    
    before do 
      @problem = mock_model(Problem, :emailable_organizations => [], 
                                     :unemailable_organizations => [],
                                     :campaign => nil)
      Problem.stub!(:find).and_return(@problem)
      @sent_email = mock_model(SentEmail)
      ProblemMailer.stub!(:send_report).and_return([@sent_email])
    end
    
    it 'should look for the problem by id' do 
      Problem.should_receive(:find).with('55')
      make_request
    end
    
    it 'should resend the problem to its emailable organizations' do 
      ProblemMailer.should_receive(:send_report).with(@problem, 
                                                      @problem.emailable_organizations, 
                                                      @problem.unemailable_organizations)
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