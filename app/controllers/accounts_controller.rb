class AccountsController < ApplicationController

  before_filter :require_user, :only => [:edit, :update]
  before_filter :load_user_using_action_confirmation_token, :only => [:confirm]

  def update
    current_user.update_attributes(params[:user])
    user_email = params[:user][:email]
    if user_email
      user_email.strip!
    end
    current_user.email = user_email
    current_user.password = params[:user][:password]
    current_user.password_confirmation = params[:user][:password_confirmation]
    # if someone logged in by confirmation creates a password here, register their account
    # and set the flag showing that they've confirmed their password, also validate the password
    # as if new
    if params[:user][:password]
      current_user.force_new_record_validation = true
      current_user.registered = true
      current_user.confirmed_password = true
    end
    
    # if the user is uploading a photo, make sure the the remote url field is set to nil
    if params[:user][:profile_photo]
      current_user.profile_photo_remote_url = nil
    end
    if current_user.save
      flash[:notice] = t('accounts.edit.account_updated')
      redirect_to profile_url(current_user)
    else
      render :action => :edit
    end
  end

  def new
    @account_user = User.new
  end

  def create
    user_email = params[:user][:email]
    if user_email
      user_email.strip!
    end
    user_name = params[:user][:name]
    if user_name
      user_name.strip!
    end
    @account_user = User.find_or_initialize_by_email(user_email)
    already_registered = @account_user.registered?
    # want to force validation as if a new record 
    @account_user.ignore_blank_passwords = false
    @account_user.force_new_record_validation = true
    @account_user.registered = true
    @account_user.name = user_name
    @account_user.email = user_email
    @account_user.password = params[:user][:password]
    @account_user.password_confirmation = params[:user][:password_confirmation]
    if @account_user.valid?
      if @account_user.new_record?
        new_account = true
        # don't want to actually set them as registered until they confirm
        @account_user.registered = false
        @account_user.save_without_session_maintenance
      else
        new_account = false
        # Refresh the user, discard all the changes
        @account_user = User.find_or_initialize_by_email(user_email)
      end
      post_login_action_data = get_action_data(session)
      if action_string = post_login_action_string
        @action = action_string
      else
        @action = t('accounts.new.your_account_wont_be_created')
      end
      @worry = post_login_action_worry
      @account_user.reset_perishable_token!
      unconfirmed_model = save_post_login_action_to_database(@account_user)
      send_new_account_mail(already_registered, post_login_action_data, unconfirmed_model, new_account)
      respond_to do |format|
        format.html do
          render :template => 'shared/confirmation_sent'
        end
        format.json do
          @json = {}
          @json[:success] = true
          @json[:html] = render_to_string :template => 'shared/confirmation_sent', :layout => 'confirmation'
          render :json => @json
        end
      end
    else
      # Could be an existing user - but until they enter valid details, we want to 
      # treat them just the same as a new user - if we send an existing record back 
      # to the form, the form will assume it's an account update, not creation. So
      # create a new record and validate it (we know the email exists, so skip that validation)
      if !@account_user.new_record? 
        @account_user = @account_user.clone
        @account_user.password = params[:user][:password]
        @account_user.password_confirmation = params[:user][:password_confirmation]
        @account_user.skip_email_uniqueness_validation = true
        @account_user.valid?
      end
      respond_to do |format|
        format.html do
          render :action => :new  
        end
        format.json do
          @json = {}
          @json[:success] = false
          add_json_errors(@account_user, @json)
          render :json => @json
        end
      end
    end
  end

  def confirm
    # if the account has a password, set the user as registered, save
    if !@account_user.crypted_password.blank?
      @account_user.registered = true
      @account_user.confirmed_password = true
      @account_user.save_without_session_maintenance
      flash[:notice] = t('accounts.confirm.successfully_confirmed_account')
    else
      flash[:notice] = t('accounts.confirm.logged_in_set_password')
      session[:return_to] = edit_account_url
    end
    # a false return value indicates that a redirect has been performed
    if perform_saved_login_action == false
      return
    end
    # log in the user.
    UserSession.login_by_confirmation(@account_user)      
    redirect_back_or_default root_url
  end

  private


  def send_new_account_mail(already_registered, post_login_action_data, unconfirmed_model, new_account)
    # no one's used this email before
    if new_account
      UserMailer.deliver_new_account_confirmation(@account_user, post_login_action_data, unconfirmed_model)
    elsif ! already_registered
      # someone has used this email, but not registered
      # send them an email that will let them log in and create a password
      UserMailer.deliver_account_exists(@account_user, post_login_action_data, unconfirmed_model)
    else
      # this person already registered, send them an email to let them know
      # if this account is suspended, send the token anyway: it won't work while the account remains suspended
      UserMailer.deliver_already_registered(@account_user, post_login_action_data, unconfirmed_model)
    end
  end


end