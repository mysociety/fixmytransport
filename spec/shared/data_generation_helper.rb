def create_model(generation_low, generation_high, model_type, default_attrs)
  attrs = { :generation_low => generation_low,
            :generation_high => generation_high }.merge(default_attrs)

  instance = model_type.new(attrs)
  # status should be protected if present, so needs to be assigned separately
  if instance.respond_to?(:status=)
    instance.status = default_attrs[:status]
  end
  instance.save!
  return instance
end

module SharedBehaviours

  module DataGenerationHelper

    shared_examples_for "a model that exists in data generations" do

      describe 'when the class is set to replayable' do

        before do
          @model_type.replayable = true
        end

        it 'should be replayable' do
          instance = @model_type.new
          instance.replayable.should == true
        end

      end

      describe 'when the class is set to not replayable' do

        before do
          @model_type.replayable = false
        end

        it 'should not be replayable' do
          instance = @model_type.new
          instance.replayable.should == false
        end

      end

      describe 'when the class is not set to either replayable or not replayable' do

        before do
          @model_type.replayable = nil
        end

        it 'should be replayable' do
          instance = @model_type.new
          instance.replayable.should == true
        end

      end

      describe 'when asked for an identity hash' do

        it 'should return an identity hash for an example instance' do
          @model_type.new(@valid_attributes).identity_hash().should == @expected_identity_hash
        end

        it 'should return a temporary identity hash for an example instance or raise an error if no temporary identity keys are defined' do
          if @model_type.data_generation_options_hash[:temporary_identity_fields]
            @model_type.new(@valid_attributes).temporary_identity_hash().should == @expected_temporary_identity_hash
          else
            @expected_error = "No temporary identity fields have been defined for #{@model_type}"
            lambda{ @model_type.new(@valid_attributes).temporary_identity_hash() }.should raise_error(@expected_error)
          end
        end

      end

      describe 'when finding a model in another generation' do

        it 'should find a model in the generation' do
          old_instance = create_model(generation_low=PREVIOUS_GENERATION, generation_high=PREVIOUS_GENERATION, @model_type, @default_attrs)
          @model_type.find_in_generation(PREVIOUS_GENERATION, old_instance.id).should == old_instance
          old_instance.destroy
        end

        it 'should not find a model in the current generation' do
          current_instance = create_model(generation_low=CURRENT_GENERATION, generation_high=CURRENT_GENERATION, @model_type, @default_attrs)
          expected_error = "Couldn't find #{@model_type} with ID=#{current_instance.id}"
          lambda{ @model_type.find_in_generation(PREVIOUS_GENERATION, current_instance.id) }.should raise_error(expected_error)
          current_instance.destroy
        end

      end

      describe 'when finding a model' do

        it 'should find a model in the current generation' do
          current_instance = create_model(generation_low=CURRENT_GENERATION, generation_high=CURRENT_GENERATION, @model_type, @default_attrs)
          @model_type.find(current_instance.id).should == current_instance
          current_instance.destroy
        end

        it 'should not find a model in an older generation' do
          current_instance = create_model(generation_low=PREVIOUS_GENERATION, generation_high=PREVIOUS_GENERATION, @model_type, @default_attrs)
          expected_error = "Couldn't find #{@model_type} with ID=#{current_instance.id}"
          lambda{ @model_type.find(current_instance.id) }.should raise_error(expected_error)
          current_instance.destroy
        end

        it 'should find a model that spans the previous generation and the current generation' do
          spanning_instance = create_model(generation_low=PREVIOUS_GENERATION, generation_high=CURRENT_GENERATION, @model_type, @default_attrs)
          @model_type.find(spanning_instance.id).should == spanning_instance
          spanning_instance.destroy
        end

      end

    end

    shared_examples_for "a model that exists in data generations and has slugs" do

      describe 'when reordering slugs' do

        it 'should order slugs that are identical but in a different sequence from in the previous generation' do
            # create slugs in previous generation
            @first_old_instance = create_model(generation_low=PREVIOUS_GENERATION,
                                              generation_high=PREVIOUS_GENERATION,
                                              @model_type,
                                              @default_attrs)
            @second_old_instance = create_model(generation_low=PREVIOUS_GENERATION,
                                                generation_high=PREVIOUS_GENERATION,
                                                @model_type,
                                                @default_attrs)
            @third_old_instance = create_model(generation_low=PREVIOUS_GENERATION,
                                               generation_high=PREVIOUS_GENERATION,
                                               @model_type,
                                               @default_attrs)
            [@first_old_instance, @second_old_instance, @third_old_instance].each do |instance|
              slug = instance.slug
              Slug.connection.execute("UPDATE slugs set generation_low = #{PREVIOUS_GENERATION}, generation_high = #{PREVIOUS_GENERATION}
                                       WHERE id = #{slug.id}")
            end

            @second_new_instance = create_model(generation_low=CURRENT_GENERATION,
                                                generation_high=CURRENT_GENERATION,
                                                @model_type,
                                                @default_attrs)
            @second_new_instance.previous_id = @second_old_instance.id
            @second_new_instance.save
            @second_new_instance.slug.sequence.should == 1

            @first_new_instance = create_model(generation_low=CURRENT_GENERATION,
                                               generation_high=CURRENT_GENERATION,
                                               @model_type,
                                               @default_attrs)
            @first_new_instance.previous_id = @first_old_instance.id
            @first_new_instance.save
            @first_new_instance.slug.sequence.should == 2

            @third_new_instance = create_model(generation_low=CURRENT_GENERATION,
                                               generation_high=CURRENT_GENERATION,
                                               @model_type,
                                               @default_attrs)
            @third_new_instance.previous_id = @third_old_instance.id
            @third_new_instance.save
            @third_new_instance.slug.sequence.should == 3

            @model_type.normalize_slug_sequences(CURRENT_GENERATION)

            @model_type.find(@second_new_instance.id).slug.sequence.should == 2
            @model_type.find(@first_new_instance.id).slug.sequence.should == 1
            @model_type.find(@third_new_instance.id).slug.sequence.should == 3
        end

        after do
          [@first_old_instance, @second_old_instance, @third_old_instance,
           @first_new_instance, @second_new_instance, @third_new_instance].each do |instance|
            instance.slug.destroy
            instance.slug=nil
            instance.destroy
          end
        end
      end

    end

  end
end