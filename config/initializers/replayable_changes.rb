require 'fixmytransport/replayable_changes'
ActiveRecord::Base.send(:include, FixMyTransport::ReplayableChanges)