class PasswordResetsController < ApplicationController

  before_filter :load_user_using_action_confirmation_token, :only => [:edit, :update]
  before_filter :require_no_user

  def new
  end

  def index
    render :action => 'new'
  end

  def create
    if params[:email].to_s !~ Regexp.new("^#{MySociety::Validate.email_match_regexp}\$")
      @error_email = t('password_resets.create.please_enter_valid_email')
      respond_to do |format|
        format.html do
          render :action => :new
          return
        end
        format.json do
          @json = {}
          @json[:success] = false
          @json[:errors] = { 'email' => @error_email }
          render :json => @json
          return
        end
      end
    end
    @action = t('password_resets.new.your_password_will_not_be_changed')
    @user = User.find(:first, :conditions => ['LOWER(email) = ?', params[:email].downcase])
    if @user
      post_login_action_data = get_action_data(session)
      if action_string = post_login_action_string
        @action = action_string
      end
      @user.reset_perishable_token!
      unconfirmed_model = save_post_login_action_to_database(@user)
      UserMailer.deliver_password_reset_instructions(@user, post_login_action_data, unconfirmed_model)
    end
    respond_to do |format|
      @password_reset = true
      format.html do
        render :template => 'shared/confirmation_sent'
        return
      end
      format.json do
        @json = {}
        @json[:success] = true
        @json[:html] = render_to_string :template => 'shared/confirmation_sent', :layout => 'confirmation'
        render :json => @json
        return
      end
    end

  end

  def edit
    set_next_action_text
  end

  def update
    @account_user.ignore_blank_passwords = false
    @account_user.password = params[:user][:password]
    @account_user.password_confirmation = params[:user][:password_confirmation]
    @account_user.registered = true
    @account_user.confirmed_password = true
    @account_user.force_password_validation = true
    if @account_user.save
      flash[:notice] = t('password_resets.edit.password_updated')
      # a false return value indicates that a redirect has been performed
      if perform_saved_login_action == false
        return
      end
      redirect_back_or_default root_path
    else
      set_next_action_text
      render :action => :edit
    end
  end

  private

  def set_next_action_text
    @next_action_text = t('password_resets.edit.update_password_and_login')
    case @action_confirmation.target
    when CampaignSupporter
      @next_action_text = t('password_resets.edit.update_password_and_confirm_support')
    when Comment
      @next_action_text = t('password_resets.edit.update_password_and_confirm_comment')
    when Problem
      @next_action_text = t('password_resets.edit.update_password_and_confirm_problem')
    end
  end
end
