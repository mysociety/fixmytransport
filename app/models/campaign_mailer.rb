class CampaignMailer < ActionMailer::Base
  include MySociety::UrlMapper
  # include view helpers
  helper :application
  url_mapper # See MySociety::UrlMapper
  
  def supporter_confirmation(recipient, campaign, token)
    recipients recipient.email
    from MySociety::Config.get('CONTACT_EMAIL', 'contact@localhost')
    subject "[FixMyTransport] Confirm that you want to join \"#{campaign.title}\""
    body :campaign => campaign, :recipient => recipient, :link => main_url(confirm_join_path(:email_token => token))
  end
  
end