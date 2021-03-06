class Admin::UserSessionsController < Admin::AdminController
  skip_before_filter :require_admin_user, :only => [:create, :new]
  before_filter :save_redirect, :only => [:create]

  def new
    @admin_user_session = AdminUserSession.new
  end

  def create
    @admin_user_session = AdminUserSession.new(params[:admin_user_session])
    # Set an ID on the session to distinguish it from a normal user session
    @admin_user_session.id = :admin
    @admin_user_session.httponly = true
    @admin_user_session.secure = true
    if @admin_user_session.save
      if @admin_user_session.record.user.suspended?
        @admin_user_session.destroy # prevents revealing suspended email addresses
        # remove the user_session instance so the form gets initialized with a fresh one
        # otherwise it'll try to submit by PUT not POST
        @admin_user_session = nil
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
