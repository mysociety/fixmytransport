class PasswordResetsController < ApplicationController

  before_filter :load_user_using_perishable_token, :only => [:edit, :update]  
  before_filter :require_no_user
  
  def new
  end
  
  def create  
    @user = User.find_by_email(params[:email])  
    if @user  
      @user.deliver_password_reset_instructions!  
      @action = t(:your_password_will_not_be_changed)
      render 'shared/confirmation_sent'
    else  
      flash[:error] = t(:no_user_found_with_email)
      render :action => :new  
    end  
  end
  
  def edit    
  end
  
  def update
    @user.ignore_blank_passwords = false
    @user.password = params[:user][:password]  
    @user.password_confirmation = params[:user][:password_confirmation]  
    if @user.save  
      flash[:notice] = t(:password_updated)
      redirect_back_or_default root_path
    else  
      render :action => :edit  
    end
  end
  
  private
  
  def load_user_using_perishable_token 
    # not currently using a timeout on the tokens
    @user = User.find_using_perishable_token(params[:id], token_age=0)  
    unless @user && @user.registered?
      flash[:error] = t(:could_not_find_account)
      redirect_to root_url  
    end  
  end
  
end
