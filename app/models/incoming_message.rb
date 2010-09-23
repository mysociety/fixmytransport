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
  
  def get_main_body_text_internal
    main_part = MySociety::Email.get_main_body_text_part(self.mail)
    return MySociety::Email.convert_part_body_to_text(main_part)
  end
  
  # Returns body text as HTML with quotes flattened, and emails removed.
  def get_body_for_html_display(collapse_quoted_sections = true)
    text = get_main_body_text_internal
    text = MySociety::Format.simplify_angle_bracketed_urls(text)
    text = CGI.escapeHTML(text)
    text = MySociety::Format.make_clickable(text, :contract => 1)
    return MySociety::Email.clean_linebreaks(text)
  end
  
  # class methods
  def self.create_from_tmail(tmail, raw_email_data, campaign)
    ActiveRecord::Base.transaction do
      raw_email = RawEmail.create(:data => raw_email_data)
      incoming_message = create(:subject => tmail.subject, 
                                :campaign => campaign, 
                                :raw_email => raw_email)
    end
  end
  
end
