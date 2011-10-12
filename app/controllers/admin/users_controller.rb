class Admin::UsersController < Admin::AdminController
  
  def index
    @users = User.find_by_sql("SELECT users.*, comment_count 
                               FROM users, (SELECT user_id, count(*) as comment_count
                                            FROM comments 
                                            GROUP BY user_id) as comment_counts
                               WHERE users.id = comment_counts.user_id
                               ORDER by comment_count desc")
  end

  def show
    @user = User.find(params[:id])
  end
  
  def update
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      msgs = []
      @user.is_admin = params[:user][:is_admin] == '1'? true : false          # clunky i
      @user.is_suspended = params[:user][:is_suspended] == '1'? true : false  # clunky ii
      @user.is_expert = params[:user][:is_expert] == '1'? true : false        # clunky iii
      if @user.is_admin_changed? 
        if @user.is_admin
          msgs << t('admin.user_now_administrator')
        else
          msgs << t('admin.user_now_not_admin')
        end
      end
      if @user.is_suspended_changed?
        if @user.is_suspended
          msgs << t('admin.user_now_suspended')
        else
          msgs << t('admin.user_now_unsuspended')
        end
      end
      if @user.is_expert_changed?
        if @user.is_expert
          msgs << t('admin.user_now_expert')
        else
          msgs << t('admin.user_now_normal_user')
        end
      end
      @user.save!      
      msgs << t('admin.user_updated')
      flash[:notice] = msgs.join('<br/>')
      redirect_to admin_url(admin_user_path(@user))
    else
      flash[:error] = t('admin.user_problem')
      render :show
    end
  end
  
end