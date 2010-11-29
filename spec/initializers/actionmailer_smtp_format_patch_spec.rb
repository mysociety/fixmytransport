# Spec for patch in initializers/actionmailer_smtp_format_patch.rb
require 'spec_helper'
require "#{RAILS_ROOT}/vendor/rails/actionmailer/test/abstract_unit"
class TestMailer < ApplicationMailer

  def from_with_name
    from       "System <system@localhost>"
    recipients "root@localhost"
    body       "Nothing to see here."
  end

  def from_without_name
    from       "system@localhost"
    recipients "root@localhost"
    body       "Nothing to see here."
  end

end

describe 'the patched version of actionmailer working with smtp' do
    
  before do 
    set_delivery_method(:smtp)
  end
  
  after do
    restore_delivery_method
  end
  
  describe 'when delivering mail from an address without a name' do
 
    it 'should set the from address for the mail correctly' do 
      
      TestMailer.deliver_from_without_name
      mail = MockSMTP.deliveries.first
      assert_not_nil mail
      mail, from, to = mail
      assert_equal 'system@localhost', from.to_s
    end
  end

  describe 'when delivering mail from an address with a name' do 
    
    it 'should set the from address for the mail correctly' do 
      TestMailer.deliver_from_with_name
      mail = MockSMTP.deliveries.first
      assert_not_nil mail
      mail, from, to = mail

      assert_equal 'system@localhost', from.to_s
    end
    
  end

end
