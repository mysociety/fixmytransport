class Admin::CommentsController < Admin::AdminController

  before_filter :require_can_admin_issues

  def show
    @comment = Comment.find(params[:id])
  end

  def update
    @comment = Comment.find(params[:id])
    @comment.status_code = params[:comment][:status_code]
    if @comment.update_attributes(params[:comment])
      flash[:notice] = t('admin.comment_updated')
      redirect_to admin_url(admin_comment_path(@comment.id))
    else
      flash[:error] = t('admin.comment_problem')
      render :show
    end
  end

end