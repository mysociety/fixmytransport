class Admin::AssignmentsController < Admin::AdminController

  def show 
    @assignment = Assignment.find(params[:id])
  end
end