class AccountsController < ApplicationController

  before_filter :require_user, :except => [:new, :create, :confirm]
  before_filter :load_user_using_perishable_token, :only => [:confirm]

  def show
  end

  def update
    current_user.update_attributes(params[:user])
    current_user.email = params[:user][:email]
    current_user.password = params[:user][:password]
    current_user.password_confirmation = params[:user][:password_confirmation]
    # if someone logged in by confirmation creates a password here, register their account
    # and set the flag showing that they've confirmed their password
    if params[:user][:password]
      current_user.registered = true
      current_user.confirmed_password = true
    end
    if current_user.save
      flash[:notice] = t(:account_updated)
      redirect_to account_url
    else
      render :action => :edit
    end
  end

  def new
    @account_user = User.new
  end

  def create
    @account_user = User.find_or_initialize_by_email(params[:user][:email])
    already_registered = @account_user.registered?
    @account_user.ignore_blank_passwords = false
    # want to force validation of passwords
    @account_user.registered = true
    @account_user.name = params[:user][:name]
    @account_user.email = params[:user][:email]
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
        @account_user = User.find_or_initialize_by_email(params[:user][:email])
      end
      post_login_action_data = get_action_data(session)
      if action_string = post_login_action_string
        @action = action_string
      else
        @action = t(:your_account_wont_be_created)
      end
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
          @json[:html] = render_to_string :template => 'shared/confirmation_sent', :layout => false
          render :json => @json
        end
      end
    else
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
      flash[:notice] = t(:successfully_confirmed_account)
    else
      flash[:notice] = t(:logged_in_set_password)
      session[:return_to] = edit_account_url
    end
    # log in the user.
    UserSession.login_by_confirmation(@account_user)
    if @account_user.post_login_action
      case @account_user.post_login_action.to_sym
      when :join_campaign
        campaign_supporter = CampaignSupporter.find_by_token(params[:email_token])
        if campaign_supporter
          campaign_supporter.confirm!
          session[:return_to] = campaign_path(campaign_supporter.campaign)
        end
      when :add_comment
        comment = Comment.find_by_token(params[:email_token])
        if comment
          comment.confirm!
          session[:return_to] = @template.commented_url(comment.commented)
        end
      when :create_problem
        problem = Problem.find_by_token(params[:email_token])
        if problem
          session[:return_to] = convert_problem_url(problem)
        end
      end
      
      @account_user.post_login_action = nil
      @account_user.save_without_session_maintenance
    end
    redirect_back_or_default root_url
  end

  private

  def load_user_using_perishable_token
    # not currently using a timeout on the tokens
    @account_user = User.find_using_perishable_token(params[:email_token], token_age=0)
    unless @account_user
      flash[:notice] = t(:could_not_find_account)
      redirect_to root_url
    end
  end

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
      UserMailer.deliver_already_registered(@account_user, post_login_action_data, unconfirmed_model)
    end
  end


end