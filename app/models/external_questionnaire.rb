class ExternalQuestionnaire < ActiveRecord::Base
  belongs_to :subject, :polymorphic => true
  before_create :generate_token

  # Makes a random token, suitable for using in URLs
  def generate_token
    self.token = MySociety::Util.generate_token
  end

  def url
    if self.questionnaire_code == "lboro"
      # For the Loughborough survey, they want to be able to identify
      # which problem or campaign the survey relates to.  We make that
      # survey identifier consist of "c" or "p" (for campaign or
      # problem) followed by the campaign / problem ID, then a dash,
      # and then the random token:
      identifier = "#{self.subject_type[0,1].downcase}#{self.subject_id.to_s}-#{self.token}"
      return "https://www.survey.lboro.ac.uk/fmt01?x1=#{identifier}"
    else
      raise "Unknown questionnnaire_code: #{self.questionnnaire_code}"
    end
  end

end
