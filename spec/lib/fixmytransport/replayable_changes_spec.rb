require 'fixmytransport/replayable_changes'
include FixMyTransport::ReplayableChanges

require 'spec_helper'

describe FixMyTransport::ReplayableChanges do

  describe 'when applying a set of changes to a model instance' do

    it 'an instance that currently has one of the intermediate values of an attribute should get the final value' do
      migration_paths = { :status => ['DEL', 'ACT', 'DEL'] }
      @stop = mock_model(Stop, :status => 'ACT')
      @stop.should_receive(:status=).with('DEL')
      apply_changes('stop', @stop, migration_paths, dryrun=true, verbose=false, [])
    end

  end

end