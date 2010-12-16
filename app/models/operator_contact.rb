class OperatorContact < ActiveRecord::Base
  belongs_to :operator
  has_many :sent_emails, :as => :recipient
  has_many :outgoing_messages, :as => :recipient
  validates_presence_of :category
  has_paper_trail

end
