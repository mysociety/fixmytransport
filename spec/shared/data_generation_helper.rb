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

    shared_examples_for "a model that exists in data generations and is versioned" do

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

      describe 'when a change is made' do

        it 'should store the version with the replayable flag set to true' do
          with_versioning do
            @instance = @model_type.new(@default_attrs)
            @instance.versions.size.should == 0
            @instance.save!
            @instance.versions.size.should == 1
            @instance.versions.first.replayable.should == true
          end
        end

        after do
            @instance.destroy
        end

      end

    end

    shared_examples_for "a model that exists in data generations" do

      describe 'when the data generation is set for all models controlled by data generations' do

        it 'should have the scope for the generation set in the call' do
          FixMyTransport::DataGenerations.in_generation(PREVIOUS_GENERATION) do
            condition_string = ["#{@model_type.quoted_table_name}.generation_low <= ?",
                                "AND #{@model_type.quoted_table_name}.generation_high >= ?"].join(" ")
            expected_scope = {:conditions => [ condition_string, PREVIOUS_GENERATION, PREVIOUS_GENERATION ]}
            @model_type.send(:scope, :find).should == expected_scope
          end
        end

        it 'should have the default scope after the call' do
          condition_string = ["#{@model_type.quoted_table_name}.generation_low <= ?",
                              "AND #{@model_type.quoted_table_name}.generation_high >= ?"].join(" ")
          expected_scope = {:conditions => [ condition_string , CURRENT_GENERATION, CURRENT_GENERATION ]}
          FixMyTransport::DataGenerations.in_generation(PREVIOUS_GENERATION) do
          end
          @model_type.send(:scope, :find).should == expected_scope
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
          @old_instance = create_model(generation_low=PREVIOUS_GENERATION, generation_high=PREVIOUS_GENERATION, @model_type, @default_attrs)
          @model_type.in_generation(PREVIOUS_GENERATION){ @model_type.find(@old_instance.id) }.should == @old_instance
          @old_instance.destroy
        end

        it 'should not find a model in the current generation' do
          @current_instance = create_model(generation_low=CURRENT_GENERATION, generation_high=CURRENT_GENERATION, @model_type, @default_attrs)
          expected_error = "Couldn't find #{@model_type} with ID=#{@current_instance.id}"
          lambda{ @model_type.in_generation(PREVIOUS_GENERATION){ @model_type.find(@current_instance.id) } }.should raise_error(expected_error)
          @current_instance.destroy
        end

        after do
          @old_instance.destroy if @old_instance
          @current_instance.destroy if @current_instance
        end
      end

      describe 'when finding a model in any generation' do

        it 'should find a model in a previous generation' do
          @old_instance = create_model(generation_low=PREVIOUS_GENERATION, generation_high=PREVIOUS_GENERATION, @model_type, @default_attrs)
          @model_type.in_any_generation{ @model_type.find(@old_instance.id) }.should == @old_instance
          @old_instance.destroy
        end

        it 'should find a model in the current generation' do
          @current_instance = create_model(generation_low=CURRENT_GENERATION, generation_high=CURRENT_GENERATION, @model_type, @default_attrs)
          @model_type.in_any_generation(){ @model_type.find(@current_instance.id) }.should == @current_instance
          @current_instance.destroy
        end

        after do
          @old_instance.destroy if @old_instance
          @current_instance.destroy if @current_instance
        end

      end

      describe "when finding the successor to a set of find parameters" do

        before do
          @find_params = [55]
          if @scope_model
            @find_params << { :scope => @default_params[:scope], :include => [@scope_field] }
          end
        end

        it 'should look for an instance matching the find parameters in the previous generation' do
          @model_type.should_receive(:in_generation).with(PREVIOUS_GENERATION).and_yield
          # not really testing that this is in the scope of the previous generation
          @model_type.should_receive(:find).with(*@find_params).and_return(@previous)
          @model_type.find_successor(*@find_params)
        end

        describe 'if an instance can be found in a previous generation' do

          before do
            @previous = mock_model(@model_type, :generation_high => PREVIOUS_GENERATION,
                                                :generation_low => PREVIOUS_GENERATION,
                                                :identity_hash => { :id => 55 } )
            # this stubbed call is called in the scope of the previous generation
            @model_type.stub(:find).with(*@find_params).and_return(@previous)
          end

          it 'should look for the successor to the instance in this generation' do
            @model_type.should_receive(:find).with(:first, :conditions => ['previous_id = ?', @previous.id]).and_return(@successor)
            @model_type.find_successor(*@find_params)
          end

          describe 'if the instance is valid in this generation' do

            before do
              @previous.stub!(:generation_high).and_return(CURRENT_GENERATION)
            end

            it 'should return the instance' do
              @model_type.find_successor(*@find_params).should == @previous
            end

          end

          describe 'if the instance is not valid in this generation' do

            before do
              @previous.stub!(:generation_high).and_return(PREVIOUS_GENERATION)
              @successor = mock_model(@model_type)
              @previous_conditions = { :conditions => ['previous_id = ?', @previous.id] }
            end

            describe 'if there is a successor' do

              before do
                @model_type.stub!(:find).with(:first, @previous_conditions).and_return(@successor)
              end

              it 'should return the successor' do
                @model_type.find_successor(*@find_params).should == @successor
              end

            end

            describe 'if there is no successor' do

              before do
                @model_type.stub!(:find).with(:first, @previous_conditions).and_return(nil)
              end

              describe 'if there is a manual mapping to another object' do

                before do
                  @model_type.stub!(:manual_remaps).and_return({{:id => 55} => {:id => 99}})
                  @mapped_successor = mock_model(@model_type)
                  @model_type.stub!(:find).with(:first, :conditions => {:id => 99}).and_return(@mapped_successor)
                end

                it 'should return the manually mapped object' do
                  @model_type.find_successor(*@find_params).should == @mapped_successor
                end

              end

              describe 'if there is no manual mapping to another object' do

                it 'should return nil' do
                  @model_type.find_successor(*@find_params).should == nil
                end

              end
            end
          end
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

      describe 'when setting generations' do

        it 'should not change existing generation attribute values' do
          instance = @model_type.new
          instance.generation_low = PREVIOUS_GENERATION
          instance.generation_high = PREVIOUS_GENERATION
          instance.should_not_receive(:generation_low=)
          instance.should_not_receive(:generation_high=)
          instance.set_generations
        end

        it 'should set nil generation attributes to the current generation' do
          instance = @model_type.new
          instance.should_receive(:generation_low=).with(CURRENT_GENERATION)
          instance.should_receive(:generation_high=).with(CURRENT_GENERATION)
          instance.set_generations
        end

      end

      describe 'when saving' do

        it 'should set a persistent id if one is not set' do
          @current_generation_instance = create_model(CURRENT_GENERATION,
                                                      CURRENT_GENERATION,
                                                      @model_type,
                                                      @default_attrs)
          @current_generation_instance.persistent_id.should_not be_nil
        end

        after do
          @current_generation_instance.destroy if @current_generation_instance
        end

      end

      describe 'when validating' do

        it "should not be valid if its persistent id exists in the current data generation" do
          @current_generation_instance = create_model(CURRENT_GENERATION,
                                                      CURRENT_GENERATION,
                                                      @model_type,
                                                      @default_attrs)
          instance = @model_type.new(@default_attrs)
          instance.persistent_id = @current_generation_instance.persistent_id
          instance.valid?.should == false
          instance.errors.full_messages.should == ['Persistent ID already exists in data generation']
        end

        it 'should be valid if its persistent id exists in a previous data generation' do
          @previous_generation_instance = create_model(PREVIOUS_GENERATION,
                                                      PREVIOUS_GENERATION,
                                                      @model_type,
                                                      @default_attrs)
          instance = @model_type.new(@default_attrs)
          instance.persistent_id = @previous_generation_instance.persistent_id
          instance.valid?
          instance.valid?.should == true
        end

        after do
          @current_generation_instance.destroy if @current_generation_instance
          @previous_generation_instance.destroy if @previous_generation_instance
        end

      end

    end

    shared_examples_for "a model that exists in data generations and has slugs" do

      describe 'when reordering slugs' do


      end

    end

  end
end