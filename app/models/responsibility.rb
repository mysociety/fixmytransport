class Responsibility < ActiveRecord::Base
  belongs_to :problem
  validates_presence_of :organization_persistent_id,
                        :message => I18n.translate('problems.new.choose_operator')
  validates_presence_of :organization_type
  # when storing versions of this model, store the problem id as a separate attribute so we
  # can retrieve versions that way
  has_paper_trail :meta => { :problem_id => Proc.new{ |responsibility| responsibility.problem_id } }

  def organization
    case self.organization_type
    when 'Operator'
      return Operator.current.find_by_persistent_id(self.organization_persistent_id)
    when 'PassengerTransportExecutive'
      return PassengerTransportExecutive.current.find_by_persistent_id(self.organization_persistent_id)
    when 'Council'
      return Council.find_by_persistent_id(self.organization_persistent_id)
    end
  end
end
