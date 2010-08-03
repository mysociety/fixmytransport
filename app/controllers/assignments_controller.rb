class AssignmentsController < ApplicationController
  
  def update
    @assignment = Assignment.find(params[:id])
    Assignment.update(@assignment.id, :campaign_id => params[:campaign_id], 
                                      :user_id => params[:user_id],
                                      :task_id => params[:task_id], 
                                      :data => params[:data],
                                      :status => params[:status].to_sym)
    head :ok
  end
  
end