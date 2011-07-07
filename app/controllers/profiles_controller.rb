class ProfilesController < ApplicationController

  before_filter :require_profile_user_who_has_logged_in, :only => [:show]
  
  def show
  end

  private
  
  def require_profile_user_who_has_logged_in
    @user = User.find(params[:id], :conditions => ['login_count > 0'])
    if ! @user
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
      return false
    end
    return true
  end
  
end