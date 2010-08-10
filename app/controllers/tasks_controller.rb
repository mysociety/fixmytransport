class TasksController < ApplicationController

  def create 
    # create a task, get back a redirect
    @task = Task.new(params[:task]) 
    if @task.save
      @assignment = Assignment.find(@task.callback_params.assignment_id)
      @assignment.task_id = @task.id
      @assignment.save
      redirect_to @task.start_url
    else
      #???
    end
  end
  
  def update
    @task = Task.find(params[:id])
    @task.status = params[:task][:status]
    @task.task_data = params[:task][:task_data]
    @task.save
    
    # update the associated assignment
    if @task.provider_name == 'FixMyTransport'
      @assignment = Assignment.find(@task.callback_params.assignment_id)
      @assignment.data = {}
      @task.task_data.attributes.each do |key,value|
        @assignment.data[key] = value
      end
      
      @assignment.status = @task.status.to_sym
      @assignment.save!
    end
    if @task.return_url
      redirect_to @task.return_url
    end
  end
  
end