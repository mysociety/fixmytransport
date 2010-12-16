class IncomingMessage < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :raw_email
  validates_presence_of :campaign, :raw_email
  has_many :campaign_updates
  
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
  
  def body_for_quoting
    text = main_body_text_folded
    text.gsub!("FOLDED_QUOTED_SECTION", " ")
    text.strip!
    return text
  end
  
  def sort_date
    created_at
  end
  
  def main_body_text(regenerate=false)
    if read_attribute(:main_body_text).nil? or regenerate
      generate_main_body_text
    end
    return read_attribute(:main_body_text)
  end
  
  def main_body_text_folded(regenerate=false)
    if read_attribute(:main_body_text_folded).nil? or regenerate
      generate_main_body_text
    end
    return read_attribute(:main_body_text_folded)
  end
  
  def generate_main_body_text
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
   
    text = MySociety::Email.strip_uudecode_attachments(text)
        
    if text.size > 1000000 # 1 MB ish
      raise "main body text more than 1 MB, need to implement clipping like for attachment text, or there is some other MIME decoding problem or similar"
    end
    
    text = remove_privacy_sensitive_things(text)
    folded_quoted_text = MySociety::Email.remove_quoting(text, 'FOLDED_QUOTED_SECTION')
    self.main_body_text = text
    self.main_body_text_folded = folded_quoted_text
    self.save!
    text
  end
  
  def find_attachment(url_part_number)
    attachments = MySociety::Email.get_display_attachments(mail)
    attachment = MySociety::Email.get_attachment_by_url_part_number(attachments, url_part_number)
    attachment.body = remove_privacy_sensitive_things(attachment.body)
    attachment
  end
  
  # Returns body text as HTML with emails removed.
  def get_body_for_html_display(collapse_quoted_sections = true)
    text = main_body_text
    folded_quoted_text = main_body_text_folded
    # Remove quoted sections, adding HTML. XXX The FOLDED_QUOTED_SECTION is
    # a nasty hack so we can escape other HTML before adding the unfold
    # links, without escaping them. 
    if collapse_quoted_sections
      text = folded_quoted_text
    end
    text = MySociety::Format.simplify_angle_bracketed_urls(text)
    text = CGI.escapeHTML(text)
    text = MySociety::Format.make_clickable(text, :contract => 1)
    
    if collapse_quoted_sections
      text.strip!
      # and display link for quoted stuff
      text = text.gsub(/FOLDED_QUOTED_SECTION/, "\n\n" + '<span class="unfold_link"><a href="?unfold=1">show quoted sections</a></span>' + "\n\n")
    else
      if folded_quoted_text.include?('FOLDED_QUOTED_SECTION')
        text = text + "\n\n" + '<span class="unfold_link"><a href="?">hide quoted sections</a></span>'
      end
    end
    text.strip!
    return MySociety::Email.clean_linebreaks(text)
  end
  
  def remove_privacy_sensitive_things(text)
    text = mask_special_emails(text)
    text = MySociety::Mask.mask_emails(text)
    text = MySociety::Mask.mask_mobiles(text)
  end
  
  # Converts email addresses we know about into textual descriptions of them
  def mask_special_emails(text)
    mask_organization_emails(text)
    campaign.valid_local_parts.each do |local_part|
      text.gsub!("#{local_part}@#{campaign.domain}", "[#{campaign.title} email]")
    end
    text.gsub!(MySociety::Config.get("CONTACT_EMAIL", 'contact@localhost'), "[FixMyTransport contact email]")
    text
  end
  
  def mask_organization_emails(text, &block)
    campaign.problem.emailable_organizations.each do |organization|
      if organization.is_a? Council or organization.is_a? Operator
        emails = organization.emails
      else
        emails = [organization.email]
      end
      emails.each do |email|
        if block_given?
         text = yield [organization, email, text]
        else
          text.gsub!(email, "[#{organization.name} problem reporting email]")
        end
      end
    end
    text
  end
  
  def safe_from
    return nil unless self.from
    text = mask_organization_emails(self.from){ |organization, email, text| text.gsub(email, organization.name) }
    text = MySociety::Mask.mask_emails(text)
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
