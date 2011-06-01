class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :save_redirect

  def new
    @user_session = UserSession.new
  end

  def create
    save_post_login_action_to_session
    @user_session = UserSession.new(params[:user_session])
    respond_to do |format|
      format.html do 
        if @user_session.save
          flash[:notice] = t(:login_successful)
          perform_post_login_action
          redirect_back_or_default root_path
        else
          render :action => :new
        end
      end
      format.json do 
        @json = {}
        if @user_session.save
          @json[:success] = true
          perform_post_login_action
        else
          @json[:success] = false
          add_json_errors(@user_session, @json)
        end
        render :json => @json
      end
    end
  end

  def destroy
    if !current_user
      redirect_to login_path
      return
    end
    current_user_session.destroy
    flash[:notice] = t(:logout_successful)
    redirect_back_or_default root_url
  end
  
  # respond to an authentication token from an external source e.g. facebook
  def external
    access_token = params[:access_token]
    source = params[:source]
    path = params[:path]
    User.handle_external_auth_token(access_token, source)
    perform_post_login_action
    redirect_to path
  end
  
  private
  
  def save_redirect
    if params[:redirect] and params[:redirect].starts_with?('/')
      session[:return_to] = params[:redirect]
    end
  end
    
end

