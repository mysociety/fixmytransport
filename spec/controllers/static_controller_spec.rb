require 'spec_helper'

describe StaticController do

  describe 'GET #feedback' do

    def make_request
      get :feedback
    end

    it 'should render the feedback template' do
      make_request
      response.should render_template('static/feedback')
    end

  end

  describe 'POST #feedback' do

    integrate_views

    before do
      @default_params = {:feedback => {:email => 'test@example.com',
                                       :message => 'Nice website',
                                       :name => 'Feedback Giver',
                                       :subject => 'Like it'}}
    end

    def make_request(params=@default_params)
      post :feedback, params
    end

    it 'should show the "thanks" message' do
      make_request
      flash[:notice].should == 'Thanks for your feedback!'
    end

    it 'should redirect to the front page' do
      make_request
      response.should redirect_to(root_url)
    end

    describe 'when the spam-detecting "website" field is not filled in' do

      it 'should send the feedback to the site contact address' do
        ProblemMailer.should_receive(:deliver_feedback)
        make_request
      end

    end

    describe 'when the spam-detecting "website" field is not filled in' do

      it 'should not send the feedback' do
        ProblemMailer.should_not_receive(:deliver_feedback)
        make_request(@default_params.merge({:feedback => {:email => 'test@example.com',
                                                         :message => 'Nice website',
                                                         :name => 'Feedback Giver',
                                                         :subject => 'Like it',
                                                         :website => 'Anything'}}))
      end

    end

  end

end
