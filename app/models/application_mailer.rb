class ApplicationMailer < ActionMailer::Base
  
  include MySociety::UrlMapper
  helper :application
  add_template_helper(ApplicationHelper)
  url_mapper # See MySociety::UrlMapper

  def contact_from_name_and_email
    I18n.translate('mailers.contact_from', :contact => MySociety::Config.get("CONTACT_EMAIL", 'contact@localhost'))
  end
  
  def experts_from_name_and_email(expert=nil)
    if expert
      name = expert.name
    else
      name = I18n.translate('mailers.boffins')
    end
    "#{name} <#{MySociety::Config.get('EXPERT_EMAIL', 'contact@localhost')}>"
  end
  
  def comment_confirmation_subject(comment)
    if comment.commented.is_a?(Campaign)
      comment_type = I18n.translate('mailers.comment_comment')
    else
      comment_type = I18n.translate('mailers.comment_update')
    end
    I18n.translate('mailers.comment_confirmation_subject', :comment_type => comment_type)
  end
  
  def supporter_confirmation_subject(campaign)
    I18n.translate('mailers.supporter_confirmation_subject', :campaign => campaign.title)
  end
  
  def problem_confirmation_subject()
    I18n.translate('mailers.problem_confirmation_subject')
  end
  
end