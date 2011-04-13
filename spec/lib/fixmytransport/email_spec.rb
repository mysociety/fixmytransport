require 'spec_helper'

describe FixMyTransport::Email do
  
  def load_example(filename)
    filepath = File.join(RAILS_ROOT, 'spec', 'examples', 'email', "#{filename}.txt")
    content = File.read(filepath)
  end

  def example_mail(filename)
    mail_body = load_example(filename)
    mail = FixMyTransport::Email::Mail.parse(mail_body)
    mail.base64_decode
    mail  
  end

  describe 'when managing attachments' do 
    
    before do
      @mail = example_mail('attachments')
    end

    it 'should flatten attachments' do
      attachments = FixMyTransport::Email.get_display_attachments(@mail)
      assert_equal(3, attachments.size)
    end
  
    it 'should manage having the same filename twice' do
      attachments = FixMyTransport::Email.get_display_attachments(@mail)
      assert_equal('Same attachment twice.txt', attachments[0].display_filename)
      assert_equal('hello.txt', attachments[1].display_filename)
      assert_equal('hello.txt', attachments[2].display_filename)
    end
  
    it 'should manage custom display names' do
      attachments = FixMyTransport::Email.get_display_attachments(@mail) do |filename|
        custom_name = filename ? "custom_#{filename}" : nil
        custom_name
      end
      assert_equal('Same attachment twice.txt', attachments[0].display_filename)
      assert_equal('custom hello.txt', attachments[1].display_filename)
      assert_equal('custom hello.txt', attachments[2].display_filename)    
    end
  
    it 'should manage display names with slashes' do
      attributes = {:filename => "FOI/09/066 RESPONSE TO FOI REQUEST RECEIVED 21st JANUARY 2009.txt"}
      attachment = FixMyTransport::Email::Attachment.new(attributes)
      expected_display_filename = "FOI 09 066 RESPONSE TO FOI REQUEST RECEIVED 21st JANUARY 2009.txt"
      assert_equal(expected_display_filename, attachment.display_filename)
    end
  
    it 'should manage slashes in the subjects of attachments' do
      attachment = FixMyTransport::Email::Attachment.new({:content_type => 'text/plain'})
      attachment.is_email = true
      attachment.subject = "FOI/09/066 RESPONSE TO FOI REQUEST RECEIVED 21st JANUARY 2009"
      expected_display_filename = "FOI 09 066 RESPONSE TO FOI REQUEST RECEIVED 21st JANUARY 2009.txt"
      assert_equal(expected_display_filename, attachment.display_filename)
    end
  
  end

  describe "when handling attachment headers" do

    before do
      @mail = example_mail('attachment_headers')
    end
  
    it 'should add attachment headers' do 
      attachments = FixMyTransport::Email.get_display_attachments(@mail)
      attachment = attachments.first.body
      assert_match('From: Sender <sender@example.com>', attachment)
      assert_match('To: Recipient <recipient@example.com>', attachment)
      assert_match('Cc: CC Recipient <cc@example.com>, CC Recipient 2 <cc2@example.com>, CC Recipient 3 <cc3@example.com>', attachment)
    end
  
    it 'should not add a blank header' do 
      attachments = FixMyTransport::Email.get_display_attachments(@mail)
      attachment = attachments.first.body
      assert_no_match(/Date:/, attachment)
    end
  
  end

  describe 'when handling OFT attachments' do 
    
    before do
      @mail = example_mail('oft_attachments')
    end
  
    it 'should flatten attachments' do
      attachments = FixMyTransport::Email.get_display_attachments(@mail)
      assert_equal(2,attachments.size)
    end
  
    it 'should handle attachment filenames' do
      attachments = FixMyTransport::Email.get_display_attachments(@mail)
      # picks HTML rather than text by default, as likely to render better
      assert_equal('test.html', attachments[0].display_filename)
      assert_equal('attach.txt', attachments[1].display_filename)
    end
  
  end

  describe 'when handling TNEF attachments' do 
    
    before do
      @mail = example_mail('tnef')
    end
  
    it 'should flatten attachments' do    
      attachments = FixMyTransport::Email.get_display_attachments(@mail)
      assert_equal(2, attachments.size)
    end
  
    it 'should handle attachment filenames' do
      attachments = FixMyTransport::Email.get_display_attachments(@mail)
      assert_equal('FOI 09 02976i.doc', attachments[0].display_filename)
      assert_equal('FOI 09 02976iii.doc', attachments[1].display_filename)
    end

  end

  describe 'when handling addresses' do    

    it 'should create an address from a name and email' do
      address = FixMyTransport::Email::Address.address_from_name_and_email("Example Name", "email@example.com")
      assert_equal("Example Name", address.name)
      assert_equal("email@example.com", address.address)
    end
  
  end

describe 'when folding email content' do  
  
    it 'should leave space between the main and quoted sections' do
      text = "www.some.gov.uk\n \n  \n \n  \n \n -----Original Message-----\n From: [x]\n [mailto:x]"
      folded_text = FixMyTransport::Email.remove_quoting(text, "FOLDED_QUOTED_SECTION")
      assert_equal("www.some.gov.uk FOLDED_QUOTED_SECTION", folded_text)
    end

  end

  describe 'when handling attachment text' do 
    
    it 'should extract text from HTML' do
      html_text = "some <b>HTML</b> for decoding"
      text = FixMyTransport::Email._get_attachment_text_internal_one_file("text/html", html_text)
      assert_equal("   some HTML for decoding\n\n\n", text)
    end
  
  end

  describe 'when handling uuencoding' do
    
    before do
      @mail = example_mail('bad_uuencoding')
    end
  
    it 'should decode bad uuencoding' do
      attachments = FixMyTransport::Email.get_display_attachments(@mail)
      assert_equal(1, attachments.size)
      assert_equal('moo.txt', attachments[0].filename)
    end
  
    it 'should uudecode attachments' do
      main_part = FixMyTransport::Email.get_main_body_text_part(@mail)
      attachments = FixMyTransport::Email.get_main_body_text_uudecode_attachments(@mail, main_part)
    end
  
  end

end
