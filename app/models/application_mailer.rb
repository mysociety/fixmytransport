class ApplicationMailer < ActionMailer::Base
  
  include MySociety::UrlMapper
  helper :application
  add_template_helper(ApplicationHelper)
  url_mapper # See MySociety::UrlMapper

  def contact_from_name_and_email
    "FixMyTransport <#{MySociety::Config.get("CONTACT_EMAIL", 'contact@localhost')}>"
  end
  
  def experts_from_name_and_email(expert=nil)
    if expert
      name = expert.name
    else
      name = "FixMyTransport Boffins"
    end
    "#{name} <#{MySociety::Config.get('EXPERT_EMAIL', 'contact@localhost')}>"
  end
  
  def comment_confirmation_subject(comment)
    if comment.commentable.is_a?(Campaign)
      comment_type = 'comment'
    else
      comment_type = 'update'
    end
    "[FixMyTransport] Confirm your #{comment_type}"
  end
  
  def supporter_confirmation_subject(campaign)
    "[FixMyTransport] Confirm that you want to join \"#{campaign.title}\""
  end
  
  def problem_confirmation_subject()
    "[FixMyTransport] Confirm your problem"
  end
  
end