class Assignment < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :user
  serialize :data
  belongs_to :problem
  
  STATUS_CODES = { 0 => 'In Progress', 
                   1 => 'Complete' }
  
  SYMBOL_TO_STATUS_CODE = STATUS_CODES.inject({}) do |hash, (code, message)|
    hash[message.gsub(/ /, "").underscore.to_sym] = code
    hash
  end
  
  STATUS_CODE_TO_SYMBOL = SYMBOL_TO_STATUS_CODE.invert

  named_scope :completed, :conditions => ["status_code = ?", SYMBOL_TO_STATUS_CODE[:complete]]
  
  def status
    STATUS_CODE_TO_SYMBOL[status_code]
  end
  
  def status=(symbol)
    code = SYMBOL_TO_STATUS_CODE[symbol]
    if code.nil? 
      raise "Unknown status for assignment #{symbol}"
    end
    self.status_code = code
  end
  
  def status_description
    STATUS_CODES[status_code]
  end
  
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
  def self.complete_problem_assignment(problem, task_type_name)
    assignment = find(:first, :conditions => ["task_type_name = ? and problem_id = ? and user_id = ?", 
                                             task_type_name, problem.id, problem.reporter.id])
    assignment.status = :complete
    assignment.save
  end
  
end
