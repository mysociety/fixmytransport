class Assignment < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :user
  serialize :data
  belongs_to :problem
  has_status({ 0 => 'New', 
               1 => 'In Progress', 
               2 => 'Complete' })

  named_scope :completed, :conditions => ["status_code = ?", self.symbol_to_status_code[:complete]], :order => "updated_at"
  named_scope :incomplete, :conditions => ['status_code != ?',  self.symbol_to_status_code[:complete]], :order => "updated_at"

  def task_type
    task_type_name.underscore
  end
  
  # class methods
  
  def self.create_assignment(attributes)
    assignment = create(attributes)
    task_attributes = { :task_type_id => attributes[:task_type_name], 
                        :status => attributes[:status], 
                        :callback_params => { :assignment_id => assignment.id }}
    task = Task.new(task_attributes) 
    if task.save
      assignment.task_id = task.id
      assignment.save
    end
  end
  
  # Assumes that only the problem reporter ever gets assignments related to the problem
  def self.complete_problem_assignments(problem, task_type_names)
    task_type_names.each do |task_type_name|
      assignment = find(:first, :conditions => ["task_type_name = ? and problem_id = ? and user_id = ?", 
                                                task_type_name, problem.id, problem.reporter.id])
      if assignment
        assignment.status = :complete
        assignment.save
        begin
          task = Task.find(assignment.task_id)
          task.status = :complete
          task.save
        rescue ActiveResource::ConnectionError
        end
      end
    end
   
  end
  
end
