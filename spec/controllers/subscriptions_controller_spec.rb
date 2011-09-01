require 'spec_helper'

describe SubscriptionsController do

  describe 'POST #unsubscribe' do

    def make_request
      post :unsubscribe, :target_id => 55, :target_type => 'Campaign'
    end

    describe 'if there is no current user' do

      before do
        @controller.stub!(:current_user).and_return(nil)
      end

      it 'should return a 404' do
        make_request
        response.status.should == '404 Not Found'
      end

    end

    describe 'if there is a current user' do

      before do
        @user = mock_model(User)
        @controller.stub!(:current_user).and_return(@user)
        @campaign = mock_model(Campaign)
        @subscription = mock_model(Subscription, :target => @campaign,
                                                 :destroy => nil)
        Subscription.stub!(:find).and_return(@subscription)
      end

      it 'should look for a subscription from the current user to the target' do
        Subscription.should_receive(:find).with(:first, :conditions => ['target_id = ? AND target_type = ? AND user_id = ?',
                                                                        "55", 'Campaign', @user.id])
        make_request
      end

      it 'should remove the subscription' do
        @subscription.should_receive(:destroy)
        make_request
      end

      it 'should add a notice that the subscription has been removed' do
        make_request
        flash[:notice].should == 'You will no longer receive emails about updates or comments on this issue.'
      end

      it 'should redirect to the url of the subscription target' do
        make_request
        response.should redirect_to(campaign_url(@campaign))
      end

    end

  end

  describe 'POST #subscribe' do

    def make_request
      post :subscribe, :target_id => 44, :target_type => 'Campaign'
    end

    describe 'if there is no logged in user' do

      before do
        @controller.stub!(:current_user).and_return(nil)
      end

      it 'should return a 404' do
        make_request
        response.status.should == '404 Not Found'
      end

    end

    describe 'if there is a logged in user' do

      before do
        @campaign = mock_model(Campaign)
        Campaign.stub!(:find).and_return(@campaign)
        @user = mock_model(User)
        @controller.stub!(:current_user).and_return(@user)
      end

      it 'should find the target' do
        Campaign.should_receive(:find).with('44').and_return(@campaign)
        make_request
      end

      describe 'if no target can be found' do

        before do
          Campaign.stub!(:find).and_return(nil)
        end

        it 'should show an error notice' do
          make_request
          flash[:error].should == "We're sorry, we couldn't find your subscription. Please use the feedback link to let us know what happened."
        end

        it 'should redirect to the frontpage' do
          make_request
          response.should redirect_to(root_url)
        end

      end

      it 'should look for subscriptions for this user to this target' do
        Subscription.should_receive(:find_for_user_and_target).with(@user, @campaign.id, 'Campaign')
        make_request
      end

      describe 'if the user has a subscription' do

        before do
          @subscription = mock_model(Subscription, :target => @campaign)
          Subscription.stub!(:find_for_user_and_target).and_return(@subscription)
        end

        it 'should show a notice telling them that they are already subscribed' do
          make_request
          flash[:notice].should == 'You are already subscribed to updates and comments on this issue.'
        end

        it 'should redirect them to the subscription target url' do
          make_request
          response.should redirect_to(campaign_path(@campaign))
        end

      end

      describe 'if the user does not have a subscription' do

        before do
          Subscription.stub!(:find_for_user_and_target).and_return(nil)
        end

        it 'should create a confirmed subscription' do
          time_now = Time.now
          Time.stub!(:now).and_return(time_now)
          Subscription.should_receive(:create!).with(:user => @user, :target => @campaign, :confirmed_at => time_now)
          make_request
        end

        it 'should show a notice telling them that they have been subscribed' do
          make_request
          flash[:notice].should == 'You will now receive updates and comments on this issue by email.'
        end

        it 'should redirect to the target url' do
          make_request
          response.should redirect_to(campaign_path(@campaign))
        end

      end

    end

  end

  describe 'GET #confirm_unsubscribe' do

    def make_request
      get :confirm_unsubscribe, :email_token => 'mytoken'
    end

    it 'should look for a subscription with the email token passed' do
      Subscription.should_receive(:find_by_token).with('mytoken')
      make_request
    end

    describe 'if there is a subscription' do

      before do
        @mock_campaign = mock_model(Campaign)
        @mock_subscription = mock_model(Subscription, :destroy => true,
                                                      :target => @mock_campaign)
        Subscription.stub!(:find_by_token).and_return(@mock_subscription)
      end

      it 'should show the "confirm_unsubscribe" template' do
        make_request
        response.should render_template("confirm_unsubscribe")
      end

    end

    describe 'if there is no subscription' do

      before do
        Subscription.stub!(:find_by_token).and_return(nil)
      end

      it 'should display an error flash' do
        make_request
        flash[:error].should == "We're sorry, but we could not find your subscription. If you are having issues, try copying and pasting the URL from your email into your browser. If that doesn't work, use the feedback link to get in touch."
      end

      it 'should redirect to the front page' do
        make_request
        response.should redirect_to(root_url)
      end

    end

  end

  describe 'POST #confirm_unusbscribe' do

    def make_request
      post :confirm_unsubscribe, :email_token => 'mytoken'
    end

    describe 'if there is a subscription to a problem' do

      before do
        @mock_problem = mock_model(Problem)
        @mock_subscription = mock_model(Subscription, :destroy => true,
                                                      :target => @mock_problem)
        Subscription.stub!(:find_by_token).and_return(@mock_subscription)
      end

      it 'should destroy the subscription' do
        @mock_subscription.should_receive(:destroy)
        make_request
      end

      it 'should redirect to the problem page' do
        make_request
        response.should redirect_to(problem_path(@mock_problem))
      end

      it 'should display a notice that the user is no longer subscribed to the problem' do
        make_request
        flash[:notice].should == 'You will no longer receive emails about updates on this problem report.'
      end

    end

    describe 'if there is a subscription to a campaign' do

      before do
        @mock_campaign = mock_model(Campaign)
        @mock_subscription = mock_model(Subscription, :destroy => true,
                                                      :target => @mock_campaign)
        Subscription.stub!(:find_by_token).and_return(@mock_subscription)
      end

      it 'should destroy the subscription' do
        @mock_subscription.should_receive(:destroy)
        make_request
      end

      it 'should redirect to the campaign page' do
        make_request
        response.should redirect_to(campaign_path(@mock_campaign))
      end

      it 'should display a notice that the user is no longer subscribed to the problem' do
        make_request
        flash[:notice].should == 'You will no longer receive emails about updates and comments on this issue.'
      end

    end

  end
end