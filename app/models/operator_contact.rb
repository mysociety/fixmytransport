class OperatorContact < ActiveRecord::Base
  belongs_to :operator
  has_many :sent_emails, :as => :recipient
  has_many :outgoing_messages, :as => :recipient
  validates_presence_of :category
  belongs_to :location, :polymorphic => true
  has_paper_trail
  
  def name
    operator.name
  end
  
  def last_editor
    return nil if versions.empty? 
    return versions.last.whodunnit
  end

end
