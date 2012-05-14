require 'spec_helper'
describe 'Patched slugged models' do

  describe 'when finding a model using a slug' do

    def create_old_slug(name, scope, stop)
      slug = Slug.new(:scope => scope,
                      :name => name)
      slug.generation_low = PREVIOUS_GENERATION
      slug.generation_high = PREVIOUS_GENERATION
      slug.sluggable_id = stop.id
      slug.sluggable_type = 'Stop'
      slug.save!
      return slug
    end

    before do
      @locality = Locality.create!(:name => 'Kenty')
      @first_stop = Stop.new(:common_name => 'Kent Lane',
                             :locality => @locality,
                             :stop_type => 'BCT')
      @first_stop.status = 'ACT'
      @first_stop.save!
      @old_slug = create_old_slug('old-name', 'old-scope', @first_stop)
    end

    it 'should not find a model using a slug from another data generation' do
      expected_error = "Couldn't find Stop with ID=old-name, scope: old-scope"
      lambda{ Stop.find('old-name', :scope => 'old-scope') }.should raise_error(expected_error)
    end

    it 'should find a model using a slug from the current generation' do
      Stop.find('kent-lane', :scope => 'kenty').should == @first_stop
    end

    after do
      @first_stop.destroy
      @old_slug.destroy
      @locality.destroy
    end
  end

end

