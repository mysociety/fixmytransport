class SubscriptionsController < ApplicationController
  
  def confirm_unsubscribe
    @subscription = Subscription.find_by_token(params[:email_token])
    if @subscription
      target = @subscription.target
      @subscription.destroy
      flash[:notice] = t('subscriptions.confirm_unsubscribe.no_longer_subscribed_to_problem')
      redirect_to(problem_path(target))
    else
      flash[:error] = t('subscriptions.confirm_unsubscribe.could_not_find_subscription')
      redirect_to(root_url)
    end
  end
  
end