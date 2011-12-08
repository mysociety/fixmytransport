class Admin::UsersController < Admin::AdminController

  before_filter :require_can_admin_users

  def index
    conditions = []
    if !params[:query].blank?
      conditions = User.name_or_email_or_id_conditions(params[:query])
    end
    @users = User.paginate :page => params[:page],
                           :conditions => conditions,
      #                     :include => :comment_count,
                           :order => 'lower(name)'

  end

  # displays a flat table of users ordered by number of comments
  def comment_league
    @users = User.find_by_sql("SELECT users.*, comment_count
                               FROM users, (SELECT user_id, count(*) as comment_count
                                            FROM comments
                                            GROUP BY user_id) as comment_counts
                               WHERE users.id = comment_counts.user_id
                               ORDER by comment_count desc, users.is_admin desc, users.is_expert desc")
  end

  def show
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      msgs = []
      protected_attrs = [:is_admin, :is_suspended, :is_expert,
                         :can_admin_locations, :can_admin_users, :can_admin_issues, :can_admin_organizations]
      protected_attrs.each do |attribute|
        @user.send("#{attribute}=".to_sym, params[:user][attribute] == '1'? true : false)
      end
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