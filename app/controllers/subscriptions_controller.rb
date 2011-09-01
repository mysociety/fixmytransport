class SubscriptionsController < ApplicationController

  def confirm_unsubscribe
    @subscription = Subscription.find_by_token(params[:email_token])
    if @subscription
      if request.post?
        target = @subscription.target
        @subscription.destroy
        if target.is_a?(Problem)
          flash[:notice] = t('subscriptions.confirm_unsubscribe.no_longer_subscribed_to_problem')
          redirect_to(problem_path(target))
        elsif target.is_a?(Campaign)
          flash[:notice] = t('subscriptions.confirm_unsubscribe.no_longer_subscribed_to_campaign')
          redirect_to(campaign_path(target))
        end
      end
    else
      flash[:error] = t('subscriptions.confirm_unsubscribe.could_not_find_subscription')
      redirect_to(root_url)
    end
  end

  def subscribe
    if current_user
      target = params[:target_type].constantize.find(params[:target_id])
      if !target
        flash[:error] = t('subscriptions.subscribe.could_not_find_subscription')
        redirect_to(root_path)
        return
      end
      subscription = Subscription.find_for_user_and_target(current_user, target.id, target.class.to_s)
      if subscription
        if target.is_a?(Problem)
          flash[:notice] = t('subscriptions.subscribe.already_subscribed_to_problem')
          redirect_to(problem_path(target))
          return
        elsif target.is_a?(Campaign)
          flash[:notice] = t('subscriptions.subscribe.already_subscribed_to_campaign')
          redirect_to(campaign_path(target))
          return
        end
      else
        Subscription.create!(:user => current_user, :target => target, :confirmed_at => Time.now)
        if target.is_a?(Problem)
          flash[:notice] = t('subscriptions.subscribe.subscribed_to_problem')
          redirect_to(problem_path(target))
          return
        elsif target.is_a?(Campaign)
          flash[:notice] = t('subscriptions.subscribe.subscribed_to_campaign')
          redirect_to(campaign_path(target))
          return
        end
      end
    else
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return
    end
  end

  def unsubscribe
    if current_user
      subscription = Subscription.find_for_user_and_target(current_user, params[:target_id], params[:target_type])
      target = subscription.target
      subscription.destroy
      if target.is_a?(Problem)
        flash[:notice] = t('subscriptions.unsubscribe.no_longer_subscribed_to_problem')
        redirect_to(problem_path(target))
      elsif target.is_a?(Campaign)
        flash[:notice] = t('subscriptions.unsubscribe.no_longer_subscribed_to_campaign')
        redirect_to(campaign_path(target))
      end
    else
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return
    end
  end

end