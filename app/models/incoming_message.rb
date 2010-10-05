class IncomingMessage < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :raw_email
  validates_presence_of :campaign, :raw_email
  
  def mail 
    @mail ||= if raw_email.nil?
      nil
    else
      mail = MySociety::Email::Mail.parse(raw_email.data)
      mail.base64_decode
      mail
    end
    @mail
  end
  
  def main_body_text
    main_part = MySociety::Email.get_main_body_text_part(self.mail)
    if main_part.nil?
      text = I18n.translate(:no_body)
    else
      text = main_part.body
      # convert html to formatted plain text as we escape all html later
      if main_part.content_type == 'text/html'
        text = MySociety::Email._get_attachment_text_internal_one_file(main_part.content_type, text)
      end
    end
    text
  end
  
  def find_attachment(url_part_number)
    attachments = MySociety::Email.get_display_attachments(mail)
    attachment = MySociety::Email.get_attachment_by_url_part_number(attachments, url_part_number)
  end
  
  # Returns body text as HTML with emails removed.
  def get_body_for_html_display(collapse_quoted_sections = true)
    text = main_body_text
    text = remove_privacy_sensitive_things(text)
    text = MySociety::Format.simplify_angle_bracketed_urls(text)
    text = CGI.escapeHTML(text)
    text = MySociety::Format.make_clickable(text, :contract => 1)
    return MySociety::Email.clean_linebreaks(text)
  end
  
  def remove_privacy_sensitive_things(text)
    text = mask_special_emails(text)
    text = MySociety::Mask.mask_emails(text)
    text = MySociety::Mask.mask_mobiles(text)
  end
  
  # Converts email addresses we know about into textual descriptions of them
  def mask_special_emails(text)
    campaign.problem.emailable_organizations.each do |organization|
      text.gsub!(organization.email, "[#{organization.name} problem reporting email]")
    end
    campaign.valid_local_parts.each do |local_part|
      text.gsub!("#{local_part}@#{campaign.domain}", "[#{campaign.title} email]")
    end
    text.gsub!(MySociety::Config.get("CONTACT_EMAIL", 'contact@localhost'), "[FixMyTransport contact email]")
    text
  end
    
  # Return date mail was sent
  def sent_at
    # Use date it arrived (created_at) if mail itself doesn't have Date: header
    self.mail.date || self.created_at
  end
  
  # class methods
  def self.create_from_tmail(tmail, raw_email_data, campaign)
    ActiveRecord::Base.transaction do
      raw_email = RawEmail.create(:data => raw_email_data)
      incoming_message = create(:subject => tmail.subject, 
                                :campaign => campaign, 
                                :raw_email => raw_email,
                                :from => tmail.friendly_from)
    end
  end
  
end
