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
    if current_user.save  
      flash[:notice] = t(:account_updated)
      redirect_to account_url
    else  
      render :action => :edit  
    end
  end
  
  def new
    @user = User.new
  end
  
  def create
    @user = User.find_or_initialize_by_email(params[:user][:email])
    already_registered = @user.registered?
    @user.ignore_blank_passwords = false
    # want to force validation of passwords
    @user.registered = true
    @user.name = params[:user][:name]
    @user.email = params[:user][:email]
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
    if @user.valid? 
      # no one's used this email before, or someone has, but not registered
      if @user.new_record? or ! already_registered
        # don't want to actually set them as registered until they confirm
        @user.registered = false
        @user.save_without_session_maintenance
        @user.deliver_new_account_confirmation!
        @action = t(:your_account_wont_be_created)
        render :template => 'shared/confirmation_sent'
      else
        # this person already registered, send them an email to let them know
        # response in browser should look the same in case this is someone
        # just trying to find out if there's an account for an email address that's
        # not theirs. Refresh the user, discard all the changes
        @user = User.find_or_initialize_by_email(params[:user][:email])
        @user.deliver_already_registered!
        @action = t(:your_account_wont_be_created)
        render :template => 'shared/confirmation_sent'
      end
    else
      render :action => :new
    end
  end
  
  def confirm
    # set the user as registered, save and log in
    @user.registered = true
    @user.save
    UserSession.create(@user, remember_me=false) # Log user in manually
    flash[:notice] = t(:successfully_confirmed_account)
    redirect_back_or_default root_url
  end
  
  private
  
  def load_user_using_perishable_token 
    # not currently using a timeout on the tokens
    @user = User.find_using_perishable_token(params[:email_token], token_age=0)  
    unless @user
      flash[:notice] = t(:could_not_find_account)
      redirect_to root_url  
    end
  end
  
  
end