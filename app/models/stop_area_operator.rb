class StopAreaOperator < ActiveRecord::Base
  belongs_to :operator
  belongs_to :stop_area
  # virtual attribute used for adding new stop area operators
  attr_accessor :_add
  
  before_destroy :check_problems

  def check_problems
    conditions = ["problems.location_type = ?
                   AND problems.location_id = ?
                   AND organization_id = ?
                   AND organization_type = 'Operator'", 
                  'StopArea', self.stop_area_id, self.operator_id]
    responsibilities = Responsibility.find(:all, :conditions => conditions,
                                                 :include => :problem)
    if !responsibilities.empty?
      msg = "Cannot destroy association of stop area #{self.stop_area.id} with operator #{self.operator.id}"
      msg += " - problems need updating"
      raise FixMyTransport::Exceptions::ProblemsExistError.new(msg)
    end
    return true
  end
  
end
