require 'spec_helper'

describe Slug do

  describe 'when creating a slug for a model that is versioned by data generations' do

    before do
      @locality = Locality.new(:name => 'Slug Sequence Locality',
                               :generation_low => PREVIOUS_GENERATION,
                               :generation_high => CURRENT_GENERATION)
      @locality.save!
      @previous_stop = Stop.new(:common_name => 'Slug Sequence Test',
                                :stop_type => 'BCT',
                                :persistent_id => 66,
                                :locality => @locality)
      @previous_stop.generation_low = PREVIOUS_GENERATION
      @previous_stop.generation_high = PREVIOUS_GENERATION
      @previous_stop.status = 'ACT'
      # Call and then disable build_a_slug, so we can set up the slug in the previous
      # generation
      @previous_stop.send(:build_a_slug)
      @previous_stop.slugs.size.should == 1
      @previous_slug = @previous_stop.slugs.first
      @previous_slug.generation_low = PREVIOUS_GENERATION
      @previous_slug.generation_high = PREVIOUS_GENERATION
      @previous_stop.stub!(:build_a_slug)
      @previous_stop.save!
      Stop.in_any_generation do
        Slug.in_any_generation do
          @previous_stop = Stop.find(@previous_stop.id)
          @previous_slug = @previous_stop.slug
          @previous_slug.name.should == 'slug-sequence-test'
          @previous_slug.scope.should == 'slug-sequence-locality'
          @previous_slug.sequence.should == 1
        end
      end

      # New stop with the same name and locality, which is not a successor of the previous stop
      @not_successor = Stop.new(:common_name => 'Slug Sequence Test',
                                :stop_type => 'BCT',
                                :persistent_id => 77,
                                :locality => @locality)
      @not_successor.status = 'ACT'
      @not_successor.save!

      # Actual successor to previous stop
      @successor = Stop.new(:common_name => 'Slug Sequence Test',
                            :stop_type => 'BCT',
                            :persistent_id => 66,
                            :locality => @locality)
      @successor.status = 'ACT'
      @successor.save!
    end

    it 'should create a slug with the same sequence as a previous model with the same slug attributes
        and permanent id' do
      @successor.slug.name.should  == 'slug-sequence-test'
      @successor.slug.scope.should == 'slug-sequence-locality'
      @successor.slug.sequence.should == 1
    end

    it 'should not reuse a sequence number used in a previous for a new model with the same slug
        generation for a new model with the same attributes but a different persistent id' do
      @not_successor.slug.name.should  == 'slug-sequence-test'
      @not_successor.slug.scope.should == 'slug-sequence-locality'
      @not_successor.slug.sequence.should == 2
    end

    after do
      @previous_slug.destroy
      @previous_stop.destroy
      @not_successor.destroy
      @successor.destroy
      @locality.destroy
    end

  end
end