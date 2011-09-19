class Responsibility < ActiveRecord::Base
  belongs_to :problem
  belongs_to :organization, :polymorphic => true
  validates_presence_of :organization_id, :message => I18n.translate('problems.new.choose_operator')
  validates_presence_of :organization_type
  has_paper_trail
  
  def organization
    case self.organization_type
    when 'Operator'
      return Operator.find(self.organization_id)
    when 'PassengerTransportExecutive'
      return PassengerTransportExecutive.find(self.organization_id)
    when 'Council'
      return Council.find_by_id(self.organization_id)
    end
  end
  
end
