class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :save_redirect

  def new
    @user_session = UserSession.new
  end

  def create
    save_post_login_action_to_session
    params[:user_session][:login_by_password] = true
    @user_session = UserSession.new(params[:user_session])
    respond_to do |format|
      format.html do
        if @user_session.save
          if @user_session.record.suspended?
            @user_session.destroy # seems weird, but prevents revealing suspended emails addresses
            flash[:error] = t('shared.suspended.forbidden')
          else
            flash[:notice] = t('shared.login.login_successful')
            perform_post_login_action
          end
          redirect_back_or_default root_path
        else
          render :action => :new
        end
      end
      format.json do
        @json = {}
        if @user_session.save
          if @user_session.record.suspended?
            @user_session.destroy # seems weird, but prevents revealing suspended emails addresses
            @user_session.errors.add_to_base(t('shared.suspended.forbidden'))   # [:base] << t('shared.suspended.forbidden')
            @json[:success] = false
            add_json_errors(@user_session, @json)
          else
            @json[:success] = true
            perform_post_login_action
          end
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
    flash[:notice] = t('shared.login.logout_successful')
    redirect_back_or_default root_url
  end

  # respond to an authentication token from an external source e.g. facebook
  def external
    access_token = params[:access_token]
    source = params[:source]
    path = params[:path]
    remember_me = params[:remember_me] == 'true'
    begin
      User.handle_external_auth_token(access_token, source, remember_me)
      perform_post_login_action
    rescue StandardError => error
      # e.g., HTTP exception if FB is not responding or access_token is wrong: unexpected error at this stage
      # send an email to site error address
      notify_about_exception(error)
      flash[:error] = t('shared.login.unexpected_external_auth_error', :source => source)
    end
    redirect_back_or_default path
  end

  private

  def save_redirect
    if params[:redirect] and params[:redirect].starts_with?('/')
      session[:return_to] = params[:redirect]
    end
  end

end

