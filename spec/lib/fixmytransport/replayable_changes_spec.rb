require 'fixmytransport/replayable_changes'
include FixMyTransport::ReplayableChanges

require 'spec_helper'

describe FixMyTransport::ReplayableChanges do

  before do
    @version = mock_model(Version, :created_at => Time.now-1.day,
                                   :event => 'update',
                                   :item_id => 77,
                                   :item_type => 'Stop',
                                   :replayable= => nil)
    @version_change_hash = { :date => @version.created_at,
                             :event => "update",
                             :changes => { :common_name => ["Old name", "Locally changed name"] },
                             :version_id => @version.id,
                             :item_persistent_id => 5454 }
    @stop_update_hash = { 5454 => [ { :date => @version.created_at,
                                      :event => "update",
                                      :changes => { :common_name => ["Old name", "Locally changed name"] },
                                      :version_id=> @version.id } ] }
  end


  describe 'when getting the significant changes from a version model' do

    before do
      @nil_attrs = Hash.new(Stop.content_columns.map{ |column| [ column.name, nil ] })
      @mock_stop = mock_model(Stop, {})
    end

    describe 'if the version has no next version' do

      before do
        @version_model = mock_model(Stop, :next_version => nil,
                                          :id => 77,
                                          :persistent_id => 5454,
                                          :diff => {:common_name => ['Old name', 'Locally changed name']})
        @version.stub!(:reify).and_return(@version_model)
        Stop.stub!(:find).with(77).and_return(@mock_stop)
      end

      it 'should look for the model instance' do
        Stop.should_receive(:find).with(77).and_return(@mock_stop)
        get_changes(@version, Stop, options={}, verbose=false)
      end

      it 'should return a hash with details and identity keys' do
        info_hash = get_changes(@version, Stop, options={}, verbose=false)
        info_hash.should == @version_change_hash
      end

    end

  end

  describe 'when getting updates for a model class' do

    before do
      Version.stub!(:find).with(:all, :conditions => ['item_type = ? AND generation = ? AND replayable = ?',
                                                      'Stop', PREVIOUS_GENERATION, true],
                                      :order => 'created_at asc').and_return([@version])
      stub!(:get_changes).and_return(@version_change_hash)
    end

    it 'should look for versions of instances of that class created in the previous generation' do
      Version.should_receive(:find).with(:all, :conditions => ['item_type = ? AND generation = ? AND replayable = ?',
                                                               'Stop', PREVIOUS_GENERATION, true],
                                               :order => 'created_at asc').and_return([@version])
      get_updates(Stop, only_replayable=true, date=nil, verbose=false)
    end

    it 'should return a hash keyed on persistent_id with values being lists of changes' do
      update_hash = get_updates(Stop, only_replayable=true, date=nil, verbose=false)
      update_hash.should == @stop_update_hash
    end

  end

  describe 'when replaying updates for a model class' do

    before do
      stub!(:get_updates).with(Stop, true, nil, false).and_return(@stop_update_hash)
      @current_gen_stop = mock_model(Stop, :common_name => 'Old name',
                                           :common_name= => nil,
                                           :replay_of= => nil,
                                           :valid? => true)
      @current_gen = mock('current generation')
      @current_gen.stub!(:find_by_persistent_id).with(5454).and_return(@current_gen_stop)
      Stop.stub!(:current).and_return(@current_gen)
      Version.stub!(:find).with(@version.id).and_return(@version)
    end

    it 'should look for replayable updates' do
      should_receive(:get_updates).with(Stop, replayable=true, nil, false).and_return(@stop_update_hash)
      replay_updates(Stop, dryrun=true, verbose=false)
    end

    it 'should apply replayable updates to the instance in the current generation with the
        persistent id' do
      @current_gen.should_receive(:find_by_persistent_id).with(5454).and_return(@current_gen_stop)
      @current_gen_stop.should_receive(:common_name=).with('Locally changed name')
      replay_updates(Stop, dryrun=true, verbose=false)
    end

    it 'should mark each version whose changes have been applied as unreplayable' do
      @version.should_receive(:replayable=).with(false)
      replay_updates(Stop, dryrun=true, verbose=false)
    end

    it 'should apply a change when the current value is blank and the first value of the attribute is blank,
        but they are different e.g. nil and ""' do
      changes = { 5454 => [ { :date => @version.created_at,
                              :event => "update",
                              :changes => { :status => [nil, "ACT"] },
                              :version_id=> @version.id }] }
      stub!(:get_updates).and_return(changes)
      @current_gen_stop.stub!(:status).and_return("")
      @current_gen_stop.should_receive(:status=).with('ACT')
      replay_updates(Stop, dryrun=true, verbose=false)
    end

    it 'an instance that currently has one of the intermediate values of an attribute should get the final value' do
      changes = { 5454 => [ { :date => @version.created_at,
                              :event => "update",
                              :changes => { :status => ["DEL", "ACT"] },
                              :version_id=> @version.id },
                            { :date => @version.created_at,
                              :event => "update",
                              :changes => { :status => ["ACT", "DEL"] },
                              :version_id=> @version.id }] }
      stub!(:get_updates).and_return(changes)
      @current_gen_stop.stub!(:status).and_return('ACT')
      @current_gen_stop.should_receive(:status=).with('DEL')
      replay_updates(Stop, dryrun=true, verbose=false)
    end

  end

end