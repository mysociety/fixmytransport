class Update < ActiveRecord::Base
  belongs_to :reporter, :class_name => 'User'
  before_create :generate_confirmation_token
  after_create :send_confirmation_email
  belongs_to :problem
  validates_associated :reporter
  validates_presence_of :text
  has_paper_trail
  has_status({ 0 => 'New', 
               1 => 'Confirmed', 
               2 => 'Hidden' })
  named_scope :confirmed, :conditions => ["status_code = ?", self.symbol_to_status_code[:confirmed]], :order => "confirmed_at desc"

  # Makes a random token, suitable for using in URLs e.g confirmation messages.
  def generate_confirmation_token
    self.token = MySociety::Util.generate_token
  end
  
  def send_confirmation_email
    ProblemMailer.deliver_update_confirmation(reporter, self, token)
  end
  
  def reporter_attributes=(attributes)
    self.reporter = User.find_or_initialize_by_email(attributes[:email])
  end
  
  def confirm!
    self.status = :confirmed
    self.confirmed_at = Time.now
    if problem 
      if mark_fixed
        problem.status = :fixed
      end
      problem.updated_at = Time.now
      problem.save!
    end
    save!  
  end
  
end
