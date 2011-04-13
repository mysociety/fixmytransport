# email.rb - email handling functions
#
# Copyright (c) 2010 UK Citizens Online Democracy. All rights reserved.
# Email: louise@mysociety.org; WWW: http://www.mysociety.org/
#

$:.push(File.join(File.dirname(__FILE__), '../ruby-msg/lib'))
$:.push(File.join(File.dirname(__FILE__), '../ruby-ole/lib'))
require 'mapi/msg'
require 'mapi/convert'

module FixMyTransport

  module Email
    
    @file_extension_to_mime_type = {
        "txt" => 'text/plain',
        "pdf" => 'application/pdf',
        "rtf" => 'application/rtf',
        "doc" => 'application/vnd.ms-word',
        "docx" => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        "xls" => 'application/vnd.ms-excel',
        "xlsx" => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        "ppt" => 'application/vnd.ms-powerpoint',
        "pptx" => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        "oft" => 'application/vnd.ms-outlook',
        "msg" => 'application/vnd.ms-outlook',
        "tnef" => 'application/ms-tnef',
        "tif" => 'image/tiff',
        "gif" => 'image/gif',
        "jpg" => 'image/jpeg', # XXX add jpeg
        "png" => 'image/png',
        "bmp" => 'image/bmp',
        "html" => 'text/html', # XXX add htm
        "vcf" => 'text/x-vcard',
        "zip" => 'application/zip',
        "delivery-status" => 'message/delivery-status'
    }

    @file_extension_to_mime_type_rev = @file_extension_to_mime_type.invert

    # Returns part of an email which contains main body text, or nil if there isn't one
    def self.get_main_body_text_part(mail)
      leaves = get_leaves(mail)
      
      # Find first part which is text/plain or text/html
      # (We have to include HTML, as increasingly there are mail clients that
      # include no text alternative for the main part, and we don't want to
      # instead use the first text attachment 
      text_types = ['text/plain', 'text/html']
      leaves.each{ |part| return part if text_types.include?(part.content_type) }
    
      # Otherwise first part which is any sort of text
      leaves.each{ |part| return part if part.main_type == 'text' }
    
      # ... or if none, consider first part 
      part = leaves[0]
      # if it is a known type then don't use it, return no body (nil)
      if mimetype_to_extension(part.content_type)
        # this is guess of case where there are only attachments, no body text
        # e.g. http://www.whatdotheyknow.com/request/cost_benefit_analysis_for_real_n
        return nil
      end
      # otherwise return it assuming it is text (sometimes you get things
      # like binary/octet-stream, or the like, which are really text - XXX if
      # you find an example, put URL here - perhaps we should be always returning
      # nil in this case)
      return part
    end
    
    # Choose the best part of an email to display
    # (This risks losing info if the unchosen alternative is the only one to contain 
    # useful info, but let's worry about that another time)
    def self.get_best_part_for_display(mail)
      # Choose best part from alternatives
      best_part = nil
      # Take the last text/plain one, or else the first one
      mail.parts.each do |part|
        if not best_part
          best_part = part
        elsif part.content_type == 'text/plain'
          best_part = part
        end
      end
      # Take an HTML one as even higher priority. (They tend to render better than text/plain) 
      mail.parts.each do |part|
        if part.content_type == 'text/html'
          best_part = part
        end
      end
      best_part
    end
    
    # Convert a mail part into an attachment object
    def self.attachment_from_leaf(leaf, &filename_block)
      attachment = Attachment.new(:body => leaf.body, 
                                  :filename => Mail.get_part_file_name(leaf, &filename_block),
                                  :content_type => leaf.content_type,
                                  :url_part_number => leaf.url_part_number)
                                  
      if leaf.within_attached_email
        attachment.is_email = true
        attachment.subject = leaf.within_attached_email.subject
        
        # Test to see if we are in the first part of the attached
        # RFC822 message and it is text, if so add headers.
        # XXX should probably use hunting algorithm to find main text part, rather than
        # just expect it to be first. This will do for now though.
        if leaf.within_attached_email == leaf && leaf.content_type == 'text/plain'
          headers = ""
          for header in [ 'Date', ' ', 'From', 'To', 'Cc' ]
            if leaf.within_attached_email.header.include?(header.downcase)
              header_value = leaf.within_attached_email.header[header.downcase]
              if !header_value.blank?
                headers = headers + header + ": " + header_value.to_s + "\n"
              end
            end
          end
          attachment.body = headers + "\n" + attachment.body
        end
      end
      attachment
    end
    
    # Get a list of Attachments suitable for display
    # Accepts a block to allow alteration of the attachment filenames 
    # e.g in order to remove text
    # attachments = FixMyTransport::Email.get_display_attachments(@mail) do |filename|
    #   return nil unless filename
    #   return "custom_#{filename}"
    # end
    def self.get_display_attachments(mail, &filename_block)
      main_part = get_main_body_text_part(mail)
      leaves = get_leaves(mail)
      attachments = []
      leaves.each do |leaf|
        next if leaf == main_part
        attachments << attachment_from_leaf(leaf, &filename_block)
      end
      
      # get attachments encoded in the body
      uudecode_attachments = get_main_body_text_uudecode_attachments(mail, main_part, &filename_block)
      uudecode_attachments.each do |uudecode_attachment|
        attachments << uudecode_attachment
      end
      attachments
    end 
    
    # Returns attachments that are uuencoded in main body part
    # Accepts a block to allow alteration of the attachment filenames 
    # e.g in order to remove text
    def self.get_main_body_text_uudecode_attachments(mail, main_part, &filename_block)
      # we get the text ourselves as we want to avoid charset
      # conversions, since /usr/bin/uudecode needs to deal with those.
      # e.g. for https://secure.mysociety.org/admin/foi/request/show_raw_email/24550
      return [] if main_part.nil?
      text = main_part.body

      # Find any uudecoded things buried in it, yeuchly
      uus = text.scan(/^begin.+^`\n^end\n/sm)
      attachments = []
      uus.each do |uu|
        # Decode the string
        content = nil
        tempfile = Tempfile.new('emailuu')
        tempfile.print uu
        tempfile.flush
        IO.popen("/usr/bin/uudecode #{tempfile.path}", "r") do |child|
          content = child.read()
        end
        tempfile.close
        filename = uu.match(/^begin\s+[0-9]+\s+(.*)$/)[1]
        if block_given?
          filename = yield filename
        end
        mail.total_part_count += 1
        # Make attachment type from it, working out filename and mime type
        attachment = Attachment.new(:body => content, 
                                    :filename => filename, 
                                    :content_type => nil,
                                    :url_part_number => mail.total_part_count)
        normalise_content_type(attachment, filename)     
        attachments << attachment
      end
      return attachments
    end
    
    # Strip the uudecode parts from a piece of text
    def self.strip_uudecode_attachments(text)
      text.split(/^begin.+^`\n^end\n/sm).join(" ")
    end
    
    # Look up by URL part number to get an attachment
    def self.get_attachment_by_url_part_number(attachments, url_part_number)
      attachments.detect{ |attachment| attachment.url_part_number == url_part_number }
    end
    
    def self.get_leaves(mail)
      mail.total_part_count = 0
      return _get_leaves_recursive(mail, mail)
    end
    
    def self._get_leaves_recursive(mail, mail_part, within_attached_email = nil)
      leaves_found = []
      if mail_part.multipart?
        # pick best part
        if mail_part.sub_type == 'alternative'
          best_part = get_best_part_for_display(mail_part)
          leaves_found += _get_leaves_recursive(mail, best_part, within_attached_email)
        else
          # add all parts
          mail_part.parts.each do |part|
            leaves_found += _get_leaves_recursive(mail, part, within_attached_email)
          end
        end
      else
        
        normalise_content_type(mail_part, Mail.get_part_file_name(mail_part))
        expand_single_attachment(mail_part)
    
        # If the part is an attachment of email
        if is_attachment?(mail_part)
          leaves_found += _get_leaves_recursive(mail, mail_part.attached_email, mail_part.attached_email)
        else
          # Store leaf
          mail_part.within_attached_email = within_attached_email
          mail.total_part_count += 1
          mail_part.url_part_number = mail.total_part_count
          leaves_found += [mail_part]
        end
      end
      return leaves_found
    end
    
    def self.is_attachment?(part)
      attachment_types = ['message/rfc822', 'application/vnd.ms-outlook', 'application/ms-tnef']
      if attachment_types.include?(part.content_type)
        return true
      end
      return false
    end
    
    def self.expand_single_attachment(part)
      part_filename = Mail.get_part_file_name(part)
      if part.content_type == 'message/rfc822'
        # An email attached as text
        begin
          part.attached_email = Mail.parse(part.body)
        rescue
          part.attached_email = nil
          part.content_type = 'text/plain'
        end
      elsif part.content_type == 'application/vnd.ms-outlook' || 
          part_filename && filename_to_mimetype(part_filename) == 'application/vnd.ms-outlook'
        # An email attached as an Outlook file
        begin
          msg = Mapi::Msg.open(StringIO.new(part.body))
          part.attached_email = Mail.parse(msg.to_mime.to_s)
        rescue 
          part.attached_email = nil
          part.content_type = 'application/octet-stream'
        end
      elsif part.content_type == 'application/ms-tnef' 
        # A set of attachments in a TNEF file
        begin
          part.attached_email = TNEF.as_mail(part.body)
        rescue
          part.attached_email = nil
          # Attached mail didn't parse, so treat as binary
          part.content_type = 'application/octet-stream'
        end
      end
    end
    
    # Given file name and its content, return most likely type
    def self.filename_and_content_to_mimetype(filename, content)
      
      # Try filename
      ret = filename_to_mimetype(filename)
      if !ret.nil?
        return ret
      end

      # If mahoro isn't installed, don't try and use it
      begin
        require 'mahoro'
      rescue LoadError
        return nil
      end
  
      # Otherwise look inside the file to work out the type.
      # Mahoro is a Ruby binding for libmagic.
      m = Mahoro.new(Mahoro::MIME)
      mahoro_type = m.buffer(content)
      mahoro_type.strip!
      # XXX we shouldn't have to check empty? here, but Mahoro sometimes returns a blank line :(
      # e.g. for InfoRequestEvent 17930
      if mahoro_type.nil? || mahoro_type.empty?
        return nil
      end
      # text/plain types sometimes come with a charset
      mahoro_type.match(/^(.*);/)
      if $1
        mahoro_type = $1
      end
      # see if looks like a content type, or has something in it that does
      # and return that
      # mahoro returns junk "\012- application/msword" as mime type.
      mahoro_type.match(/([a-z0-9.-]+\/[a-z0-9.-]+)/)
      if $1
        return $1
      end
      # otherwise we got junk back from mahoro
      return nil
    end
    
    def self.filename_to_mimetype(filename)
      if !filename
        return nil
      end
      if filename.match(/\.([^.]+)$/i)
        lext = $1.downcase
        if @file_extension_to_mime_type.include?(lext)
          return @file_extension_to_mime_type[lext]
        end
      end
      return nil
    end
    
    def self.mimetype_to_extension(mime)
      if @file_extension_to_mime_type_rev.include?(mime)
        return @file_extension_to_mime_type_rev[mime]
      end
      return nil
    end
    
    # Normalise a mail part's content_type for display
    # Use standard content types for Word documents etc.
    def self.normalise_content_type(mail_part, part_file_name)
      
      # Don't allow nil content_types
      if mail_part.content_type.nil?
        mail_part.content_type = 'application/octet-stream'
      end
      
      # PDFs often come with this mime type, fix it up for view code
      if mail_part.content_type == 'application/octet-stream'
        calc_mime = filename_and_content_to_mimetype(part_file_name, mail_part.body)
        if calc_mime
          mail_part.content_type = calc_mime
        end
      end 
      
      if ['application/excel', 'application/msexcel', 'application/x-ms-excel'].include?(mail_part.content_type)
        mail_part.content_type = 'application/vnd.ms-excel'
      end
      
      if ['application/mspowerpoint', 'application/x-ms-powerpoint'].include?(mail_part.content_type)
        mail_part.content_type = 'application/vnd.ms-powerpoint' 
      end
      
      if ['application/msword', 'application/x-ms-word'].include?(mail_part.content_type)
        mail_part.content_type = 'application/vnd.ms-word'
      end
      
      if mail_part.content_type == 'application/x-zip-compressed'
        mail_part.content_type = 'application/zip'
      end
    
      if mail_part.content_type == 'application/acrobat'
        mail_part.content_type = 'application/pdf'
      end
      
    end
    
    def self._get_attachment_text_internal_one_file(content_type, body)
      text = ''
      # XXX - tell all these command line tools to return utf-8
      if content_type == 'text/plain'
        text += body + "\n\n"
      else
        tempfile = Tempfile.new('emailextract')
        tempfile.print body
        tempfile.flush
        if content_type == 'text/html'
          # lynx wordwraps links in its output, which then don't get formatted properly
          # by WhatDoTheyKnow. We use elinks instead, which doesn't do that.
          IO.popen("/usr/bin/elinks -dump-charset utf-8 -force-html -dump " + tempfile.path, "r") do |child|
            text += child.read() + "\n\n"
          end
        end
        tempfile.close
      end
    
      return text
    end

    def self.remove_quoting(text, replacement)
      folded_quoted_text = remove_quoted_sections(text, replacement)
      # merge contiguous quoted sections
      folded_quoted_text = folded_quoted_text.gsub(/(\s*#{replacement}\s*)+/m, " #{replacement}")
    end
           
    # Remove quoted sections from emails (eventually the aim would be for this
    # to do as good a job as GMail does) XXX bet it needs a proper parser
    # XXX and this FOLDED_QUOTED_SECTION stuff is a mess
    def self.remove_quoted_sections(text, replacement = "FOLDED_QUOTED_SECTION")
      text = text.dup
      replacement = "\n" + replacement + "\n"
    
      # First do this peculiar form of quoting, as the > single line quoting
      # further below messes with it. Note the carriage return where it wraps -
      # this can happen anywhere according to length of the name/email. e.g.
      # >>> D K Elwell <[email address]> 17/03/2008
      # 01:51:50 >>>
      # http://www.whatdotheyknow.com/request/71/response/108
      # http://www.whatdotheyknow.com/request/police_powers_to_inform_car_insu
      # http://www.whatdotheyknow.com/request/secured_convictions_aided_by_cct
      multiline_original_message = '(' + '''>>>.* \d\d/\d\d/\d\d\d\d\s+\d\d:\d\d(?::\d\d)?\s*>>>''' + ')'
      text.gsub!(/^(#{multiline_original_message}\n.*)$/ms, replacement)
    
      # Single line sections
      text.gsub!(/^(>.*\n)/, replacement)
      text.gsub!(/^(On .+ (wrote|said):\n)/, replacement)
    
      # Multiple line sections
      # http://www.whatdotheyknow.com/request/identity_card_scheme_expenditure
      # http://www.whatdotheyknow.com/request/parliament_protest_actions
      # http://www.whatdotheyknow.com/request/64/response/102
      # http://www.whatdotheyknow.com/request/47/response/283
      # http://www.whatdotheyknow.com/request/30/response/166
      # http://www.whatdotheyknow.com/request/52/response/238
      # http://www.whatdotheyknow.com/request/224/response/328 # example with * * * * *
      # http://www.whatdotheyknow.com/request/297/response/506
      ['-', '_', '*', '#'].each do |score|
          text.sub!(/(Disclaimer\s+)?  # appears just before
                      (
                          \s*(?:[#{score}]\s*){8,}\s*\n.*? # top line
                          (disclaimer:\n|confidential|received\sthis\semail\sin\serror|virus|intended\s+recipient|monitored\s+centrally|intended\s+(for\s+|only\s+for\s+use\s+by\s+)the\s+addressee|routinely\s+monitored|MessageLabs|unauthorised\s+use)
                          .*?((?:[#{score}]\s*){8,}\s*\n|\z) # bottom line OR end of whole string (for ones with no terminator XXX risky)
                      )
                     /imx, replacement)
      end
    
      # Special paragraphs
      # http://www.whatdotheyknow.com/request/identity_card_scheme_expenditure
      text.gsub!(/^[^\n]+Government\s+Secure\s+Intranet\s+virus\s+scanning
                  .*?
                  virus\sfree\.
                  /imx, replacement)
      text.gsub!(/^Communications\s+via\s+the\s+GSi\s+
                  .*?
                  legal\spurposes\.
                  /imx, replacement)
      # http://www.whatdotheyknow.com/request/net_promoter_value_scores_for_bb
      text.gsub!(/^http:\/\/www.bbc.co.uk
                  .*?
                  Further\s+communication\s+will\s+signify\s+your\s+consent\s+to\s+this\.
                  /imx, replacement)
    
    
      # To end of message sections
      # http://www.whatdotheyknow.com/request/123/response/192
      # http://www.whatdotheyknow.com/request/235/response/513
      # http://www.whatdotheyknow.com/request/445/response/743
      original_message = 
          '(' + '''----* This is a copy of the message, including all the headers. ----*''' + 
          '|' + '''----*\s*Original Message\s*----*''' +
          '|' + '''----*\s*Forwarded message.+----*''' +
          '|' + '''----*\s*Forwarded by.+----*''' +
          ')'
      # Could have a ^ at start here, but see messed up formatting here:
      # http://www.whatdotheyknow.com/request/refuse_and_recycling_collection#incoming-842
      text.gsub!(/(#{original_message}\n.*)$/mi, replacement)
    
    
      # Some silly Microsoft XML gets into parts marked as plain text.
      # e.g. http://www.whatdotheyknow.com/request/are_traffic_wardens_paid_commiss#incoming-401
      # Don't replace with "replacement" as it's pretty messy
      text.gsub!(/<\?xml:namespace[^>]*\/>/, " ")
    
      return text
    end
    
    def self.clean_linebreaks(text)
      text.strip!
      text = text.gsub(/\n/, '<br>')
      text = text.gsub(/(?:<br>\s*){2,}/, '<br><br>') # remove excess linebreaks that unnecessarily space it out
      return text
    end
      
    # A subclass of TMail::Mail that adds some extra attributes
    class Mail < TMail::Mail
      attr_accessor :total_part_count
      attr_accessor :url_part_number
      attr_accessor :attached_email # when a whole email message is attached as text
      attr_accessor :within_attached_email # for parts within a message attached as text (for getting subject mainly)
    
      # Hack round bug in TMail's MIME decoding. Example request which provokes it:
      # http://rubyforge.org/tracker/index.php?func=detail&aid=21810&group_id=4512&atid=17370
      def parse(raw_data)
        TMail::Mail.parse(raw_data.gsub(/; boundary=\s+"/ims,'; boundary="'))
      end
      
      def Mail.get_part_file_name(part, &block)
        file_name = (part['content-location'] &&
                     part['content-location'].body) ||
                     part.sub_header("content-type", "name") ||
                     part.sub_header("content-disposition", "filename")
        if block_given?
          file_name = yield file_name
        end
        file_name
      end
      
    end
    
    # A subclass of TMail::Address that can be constructed from a 
    # name and email
    class Address < TMail::Address
      
      def Address.address_from_name_and_email(name, email)
        if !MySociety::Validate.is_valid_email(email)
          raise "invalid email " + email + " passed to address_from_name_and_email"    
        end
        if name.nil?
          return TMail::Address.parse(email)
        end
        # Botch an always quoted RFC address, then parse it
        name = name.gsub(/(["\\])/, "\\\\\\1")
        return TMail::Address.parse('"' + name + '" <' + email + '>')
      end
    end
    
    class Attachment 
      attr_accessor :body, :content_type, :filename, :is_email, :subject, :url_part_number
      
      def initialize(attributes)
        @body = attributes[:body]
        @content_type = attributes[:content_type]
        @filename = attributes[:filename]
        @url_part_number = attributes[:url_part_number]
      end
      
      def display_filename
        filename = self._internal_display_filename
        # Sometimes filenames have e.g. %20 in - no point butchering that
        # (without unescaping it, this would remove the % and leave 20s in there)
        filename = CGI.unescape(filename)
    
        # Remove weird spaces
        filename = filename.gsub(/\s+/, " ")
        # Remove non-alphabetic characters
        filename = filename.gsub(/[^A-Za-z0-9.]/, " ")
        # Remove spaces near dots
        filename = filename.gsub(/\s*\.\s*/, ".")
        # Compress adjacent spaces down to a single one
        filename = filename.gsub(/\s+/, " ")
        filename = filename.strip
        return filename
      end
      
      def _internal_display_filename
        calc_ext = FixMyTransport::Email.mimetype_to_extension(@content_type)
        if @filename 
          # Put right extension on if missing
          if !filename.match(/\.#{calc_ext}$/) && calc_ext
            filename + "." + calc_ext
          else
            filename
          end
        else
          if !calc_ext
            calc_ext = "bin"
          end
          if self.subject
            self.subject + "." + calc_ext
          else
            "attachment." + calc_ext
          end
        end
      end
    
    end
    
    class TNEF
    
      # Extracts all attachments from the given TNEF file as a Mail object
      # The TNEF file also contains the message body, but in general this is the
      # same as the message body in the message proper.
      def self.as_mail(content)
        main = TMail::Mail.new
        main.set_content_type 'multipart', 'mixed', { 'boundary' => TMail.new_boundary }
        Dir.mktmpdir do |dir|
          IO.popen("/usr/bin/tnef -K -C #{dir} 2> /dev/null", "w") do |f|
            f.write(content)
            f.close
            if $?.signaled?
              raise IOError, "tnef exited with signal #{$?.termsig}"
            end
            if $?.exited? && $?.exitstatus != 0
              raise IOError, "tnef exited with status #{$?.exitstatus}"
            end
          end
          found = 0
          Dir.new(dir).sort.each do |file| # sort for deterministic behaviour
            if file != "." && file != ".."
              file_content = File.open("#{dir}/#{file}", "r").read
              attachment = FixMyTransport::Email::Mail.new
              attachment['content-location'] = file
              attachment.body = file_content
              main.parts << attachment
              found += 1
            end
          end
          if found == 0
            raise IOError, "tnef produced no attachments"
          end
        end
        main
      end

    end
  end
end