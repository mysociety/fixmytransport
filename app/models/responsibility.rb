class Responsibility < ActiveRecord::Base
  belongs_to :problem
  validates_presence_of :organization_persistent_id,
                        :message => I18n.translate('problems.new.choose_operator'),
                        :if => :operator_responsibility?
  validates_presence_of :organization_id,
                        :if => :non_operator_responsibility?

  validates_presence_of :organization_type
  # when storing versions of this model, store the problem id as a separate attribute so we
  # can retrieve versions that way
  has_paper_trail :meta => { :problem_id => Proc.new{ |responsibility| responsibility.problem_id } }

  def organization
    case self.organization_type
    when 'Operator'
      return Operator.find_by_persistent_id(self.organization_persistent_id)
    when 'PassengerTransportExecutive'
      return PassengerTransportExecutive.find(self.organization_id)
    when 'Council'
      return Council.find_by_id(self.organization_id)
    end
  end

  def operator_responsibility?
    self.organization_type == 'Operator'
  end

  def non_operator_responsibility?
    ['PassengerTransportExecutive', 'Council'].include?(self.organization_type)
  end

end
