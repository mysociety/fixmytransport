class Campaign < ActiveRecord::Base
  belongs_to :reporter, :class_name => 'User'
  belongs_to :location, :polymorphic => true
  belongs_to :transport_mode
  has_many :assignments
  after_create :add_default_assignment
  validates_presence_of :title, :description
  named_scope :confirmed, :conditions => ['confirmed = ?', true], :order => 'created_at desc'
  cattr_reader :per_page, :categories
  @@per_page = 10
  @@categories = ['New route', 'Keep route', 'Get repair', 'Adopt', 'Other']

  def add_default_assignment
    self.assignments.create(:user_id => reporter.id, :task_type_name => 'write-to-transport-operator')
  end
  
  def default_assignment
    self.assignments.first
  end
  
  def self.find_recent(number)
    confirmed.find(:all, :order => 'created_at desc', :limit => number, :include => [:location, :reporter])
  end
  
end
