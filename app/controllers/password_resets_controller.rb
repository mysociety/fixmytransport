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
      flash[:notice] = t(:no_user_found_with_email)
      render :action => :new  
    end  
  end
  
  def edit    
  end
  
  def update
    @user.password = params[:user][:password]  
    @user.password_confirmation = params[:user][:password_confirmation]  
    @user.registered = true
    if @user.save  
      flash[:notice] = t(:password_updated)
      redirect_back_or_default root_path
    else  
      render :action => :edit  
    end
  end
  
  private  
  
  def load_user_using_perishable_token 
    @user = User.find_using_perishable_token(params[:id])  
    unless @user  
      flash[:notice] = t(:could_not_find_account)
      redirect_to root_url  
    end  
  end
  
end
