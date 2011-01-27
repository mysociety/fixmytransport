class AccountsController < ApplicationController
  
  before_filter :require_user
  
  def show
  end
  
  def update
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
  
end