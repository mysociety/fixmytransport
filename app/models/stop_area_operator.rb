class StopAreaOperator < ActiveRecord::Base
  belongs_to :operator
  belongs_to :stop_area
  # virtual attribute used for adding new stop area operators
  attr_accessor :_add
  
  before_destroy :check_problems

  def check_problems
    conditions = ['location_type = ? AND location_id = ? AND operator_id = ?', 
                  'StopArea', self.stop_area_id, self.operator_id]
    problems = Problem.find(:all, :conditions => conditions)
    if !problems.empty?
      msg = "Cannot destroy association of stop area #{self.stop_area.id} with operator #{self.operator.id}"
      msg += " - problems need updating"
      raise FixMyTransport::Exceptions::ProblemsExistError.new(msg)
    end
    return true
  end
  
end
