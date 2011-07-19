require 'spec_helper'

describe SubscriptionsController do
  
  describe 'GET #confirm_unsubscribe' do 
    
    def make_request
      get :confirm_unsubscribe, :email_token => 'mytoken'
    end
    
    it 'should look for a subscription with the email token passed' do 
      Subscription.should_receive(:find_by_token).with('mytoken')
      make_request
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
        flash[:notice].should == 'You are no longer subscribed to updates on this problem report.'
      end
    
    end
    
    describe 'if there is no subscription' do 
      
      before do 
        Subscription.stub!(:find_by_token).and_return(nil)
      end
      
      it 'should display an error flash' do 
        make_request
        flash[:error].should == "We're sorry, but we could not locate your subscription. If you are having issues, try copying and pasting the URL from your email into your browser. If that doesn't work, use the feedback link to get in touch."
      end
      
      it 'should redirect to the front page' do 
        make_request
        response.should redirect_to(root_url)
      end
      
    end
    
  end
  
end