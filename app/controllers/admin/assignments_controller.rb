class Admin::AssignmentsController < Admin::AdminController

  def show
    @assignment = Assignment.find(params[:id])
  end

  def update
    @assignment = Assignment.find(params[:id])
    @assignment.status_code = params[:assignment][:status_code]
    if @assignment.update_attributes(params[:assignment])
      flash[:notice] = t(:assignment_updated)
      redirect_to admin_url(admin_assignment_path(@assignment.id))
    else
      flash[:error] = t(:assignment_problem)
      render :show
    end
  end

end