module SharedBehaviours

  module DataGenerationHelper

    shared_examples_for "a model that is exists in data generations" do
      
      def create_model(generation_low, generation_high)
        @model_type.create!(:generation_low => generation_low, 
                            :generation_high => generation_high,
                            :name => 'data gen test model')
      end
      
      
      before do
        fake_data_generation(2)
      end
      
      describe 'when finding a model in another generation' do 

        it 'should find a model in the generation' do 
          old_instance = create_model(generation_low=1, generation_high=1)
          @model_type.find_in_generation(1, old_instance.id).should == old_instance
          old_instance.destroy
        end
        
        it 'should not find a model in the current generation' do 
          current_instance = create_model(generation_low=2, generation_high=2)
          expected_error = "Couldn't find #{@model_type} with ID=#{current_instance.id}"
          lambda{ @model_type.find_in_generation(1, current_instance.id) }.should raise_error(expected_error)
          current_instance.destroy
        end
        
      end
      
      describe 'when finding a model' do 
      
        it 'should find a model in the current generation' do 
          current_instance = create_model(generation_low=2, generation_high=2)
          @model_type.find(current_instance.id).should == current_instance
          current_instance.destroy
        end
        
        it 'should not find a model in an older generation' do 
          current_instance = create_model(generation_low=1, generation_high=1)
          expected_error = "Couldn't find #{@model_type} with ID=#{current_instance.id}"
          lambda{ @model_type.find(current_instance.id) }.should raise_error(expected_error)
          current_instance.destroy
        end
        
        it 'should find a model that spans the previous generation and the current generation' do 
          spanning_instance = create_model(generation_low=1, generation_high=2)
          @model_type.find(spanning_instance.id).should == spanning_instance 
          spanning_instance.destroy
        end
        
      end
      
    end
    
    shared_examples_for "a model that is exists in data generations and has slugs" do
      
      def create_model(generation_low, generation_high)
        @model_type.create!(:generation_low => generation_low, 
                            :generation_high => generation_high,
                            :name => 'test model')
      end
      
      describe 'when reordering slugs' do 
        
        before do
          fake_data_generation(2)
        end
        
        it 'should order slugs that are identical but in a different sequence from in the previous generation' do
          pending do 
            # create slugs in previous generation
            @first_old_instance = create_model(generation_low=1, generation_high=1)
            @second_old_instance = create_model(generation_low=1, generation_high=1)
            @third_old_instance = create_model(generation_low=1, generation_high=1)
            [@first_old_instance, @second_old_instance, @third_old_instance].each do |instance|
              slug = instance.slug
              Slug.connection.execute("UPDATE slugs set generation_low = 1, generation_high = 1 
                                       WHERE id = #{slug.id}")
            end
          
            @second_new_instance = create_model(generation_low=2, generation_high=2)
            @second_new_instance.previous_id = @second_old_instance.id
            @second_new_instance.save
            @second_new_instance.slug.sequence.should == 1
          
            @first_new_instance = create_model(generation_low=2, generation_high=2)
            @first_new_instance.previous_id = @first_old_instance.id
            @first_new_instance.save
            @first_new_instance.slug.sequence.should == 2
          
            @third_new_instance = create_model(generation_low=2, generation_high=2)
            @third_new_instance.previous_id = @third_old_instance.id
            @third_new_instance.save
            @third_new_instance.slug.sequence.should == 3
          
            @model_type.normalize_slug_sequences
          
            @model_type.find(@second_new_instance.id).slug.sequence.should == 2
            @model_type.find(@first_new_instance.id).slug.sequence.should == 1
            @model_type.find(@third_new_instance.id).slug.sequence.should == 3

          end
        end
        
        after do 
          [@first_old_instance, @second_old_instance, @third_old_instance,
           @first_new_instance, @second_new_instance, @third_new_instance].each do |instance|
            instance.destroy
          end
        end
      end
      
    end
  
  end
end