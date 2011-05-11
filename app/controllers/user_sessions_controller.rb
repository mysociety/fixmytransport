class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :save_redirect

  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      flash[:notice] = t(:login_successful)
      redirect_back_or_default root_path
    else
      render :action => :new
    end
  end

  def destroy
    if !current_user
      redirect_to login_path
      return
    end
    current_user_session.destroy
    flash[:notice] = t(:logout_successful)
    redirect_back_or_default login_path
  end
  
  private
  
  def save_redirect
    if params[:redirect] and params[:redirect].starts_with?('/')
      session[:return_to] = params[:redirect]
    end
  end

end

