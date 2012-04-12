require 'spec_helper'
describe 'Patched slugged models' do

  describe 'when updating the scope of a slugged model to a scope that already has more than
            one slug with the same name' do 
            
    before do
      @locality = Locality.create!(:name => 'Kenty')
      @first_stop = Stop.new(:common_name => 'Kent Lane', 
                             :locality => @locality,
                             :stop_type => 'BCT')
      @first_stop.status = 'ACT'
      @first_stop.save!
      @second_stop = Stop.new(:common_name => 'Kent Lane', 
                              :locality => @locality,
                              :stop_type => 'BCT')
      @second_stop.status = 'ACT'
      @second_stop.save!
    end
    
    it 'should increment the sequence on the slug to one more than the highest sequence of the 
        similar slugs' do 
      @new_stop = Stop.new(:common_name => 'Kent Lane',
                          :stop_type => 'BCT')
      @new_stop.status = 'ACT'
      @new_stop.save!
      @new_stop.slug.sequence.should == 1
      @new_stop.locality = @locality
      @new_stop.save!
      @new_stop.slug.sequence.should == 3
    end
    
    after do
      @first_stop.destroy
      @second_stop.destroy 
      @new_stop.destroy
    end
  end

end

