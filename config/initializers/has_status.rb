require 'has_status'
ActiveRecord::Base.send(:include, FixMyTransport::Status)