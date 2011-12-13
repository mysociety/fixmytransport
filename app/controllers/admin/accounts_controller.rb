class Admin::AccountsController < Admin::AdminController

  def edit
    @admin_user = current_user.admin_user
  end
  
  def update
    @admin_user = current_user.admin_user
    @admin_user.password = params[:admin_user][:password]
    @admin_user.password_confirmation = params[:admin_user][:password_confirmation]
    if @admin_user.save
      flash[:notice] = t('admin.account_updated')
      redirect_to admin_url(edit_admin_account_path)
    else
      render :action => :edit
    end
  end

end