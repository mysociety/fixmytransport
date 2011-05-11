class ProfilesController < ApplicationController

  before_filter :require_registered_user, :only => [:show]
  
  def show
  end

  private
  
  def require_registered_user
    @user = User.find(params[:id], :conditions => ['registered = ?', true])
    if ! @user
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return false
    end
    return true
  end
  
end