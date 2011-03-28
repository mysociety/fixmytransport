require 'fixmytransport/has_status'
ActiveRecord::Base.send(:include, FixMyTransport::Status)