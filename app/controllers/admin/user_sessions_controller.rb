class Admin::UserSessionsController < Admin::AdminController
  skip_before_filter :require_admin_user, :only => [:create, :new]
  before_filter :save_redirect, :only => [:create]

  def new
    @user_session = UserSession.new
  end

  def create
    params[:user_session][:login_by_password] = true
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      if !@user_session.record.is_admin?
        @user_session.destroy # prevents revealing non-admin accounts
        # create a new session instance to show the error message
        # otherwise the form will try to submit by PUT not POST
        @user_session = UserSession.new
        @user_session.errors.add(:password, t('activerecord.errors.models.user.attributes.password.not_admin'))
        render :action => :new
        return false
      elsif @user_session.record.suspended?
        @user_session.destroy # prevents revealing suspended emails addresses
        # remove the user_session instance so the form gets initialized with a fresh one
        # otherwise it'll try to submit by PUT not POST
        @user_session = nil
        flash[:error] = t('shared.suspended.forbidden')
        render :action => :new
        return false
      else
        flash[:notice] = t('shared.login.login_successful')
      end
      redirect_back_or_default admin_url(admin_root_path)
    else
      render :action => :new
    end
  end

  def destroy
    if !current_user
      redirect_to admin_url(admin_login_path)
      return
    end
    current_user_session.destroy
    flash[:notice] = t('shared.login.logout_successful')
    redirect_back_or_default admin_url(admin_root_path)
  end

  private

  def save_redirect
    if params[:redirect] and params[:redirect].starts_with?('/')
      session[:return_to] = admin_url(params[:redirect])
    end
  end

end
