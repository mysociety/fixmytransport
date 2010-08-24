class Campaign < ActiveRecord::Base
  belongs_to :initiator, :class_name => 'User'
  belongs_to :location, :polymorphic => true
  belongs_to :transport_mode
  has_many :assignments
  has_one :problem
  after_create :add_default_assignment
  validates_presence_of :title, :description, :on => :update
  validates_associated :initiator, :on => :update
  named_scope :confirmed, :conditions => ['confirmed = ?', true], :order => 'created_at desc'
  cattr_reader :per_page, :categories
  @@per_page = 10
  @@categories = ['New route', 'Keep route', 'Get repair', 'Adopt', 'Other']

  def add_default_assignment
    self.assignments.create(:user_id => initiator.id, :task_type_name => 'write-to-transport-operator')
  end
  
  def default_assignment
    self.assignments.first
  end
  
  def self.find_recent(number)
    confirmed.find(:all, :order => 'created_at desc', :limit => number, :include => [:location, :initiator])
  end
  
end
