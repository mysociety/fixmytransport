require 'spec_helper'

describe Admin::AssignmentsController do

  describe 'GET #show' do
  end

  describe 'POST #check' do 
    
    before do 
      @operator_contacts = mock("operator contacts association", :build => true)
      @mock_operator = mock_model(Operator, :contact_for_category_and_location => nil,
                                            :operator_contacts => @operator_contacts,
                                            :save! => true)
      Operator.stub!(:find).with("66").and_return(@mock_operator)
      @route_operators = mock("route operators association", :build => true)
      @route = mock_model(Route, :route_operators => @route_operators,
                                 :save! => true)
      @stop_area_operators = mock("stop area operators association", :build => true)
      @stop_area = mock_model(StopArea, :stop_area_operators => @stop_area_operators, 
                                        :save! => true)
      @mock_problem = mock_model(Problem, :location => @route,
                                          :operator= => true,
                                          :save! => true,
                                          :emailable_organizations => [],
                                          :organization_info => {},
                                          :reporter => mock_model(User))
      @mock_assignment = mock_model(Assignment, :problem => @mock_problem,
                                                :status= => true,
                                                :save! => true,
                                                :data => {:organization_name => 'Test Operator',
                                                          :organization_email => 'test@example.com', 
                                                          :location_only => false})
      Assignment.stub!(:find).with("55").and_return(@mock_assignment)
      Assignment.stub!(:complete_problem_assignments)
      @default_params = { :id => 55 }
    end
    
    def make_request(params=@default_params)
      post :check, params
    end
  
    describe 'if an operator id param is present' do 
      
      it 'should look for the operator' do 
        Operator.should_receive(:find).with("66").and_return(@mock_operator)
        make_request(@default_params.merge({:operator_id => 66}))
      end
      
      describe 'if the operator cannot be found' do 
        
        before do
          Operator.stub!(:find).with("66").and_raise("Couldn't find Operator with ID=66")
        end
        
        it 'should set the error flash' do 
          make_request(@default_params.merge({:operator_id => 66}))
          flash[:error].should == "Couldn't find Operator with ID=66"
        end

        it 'should redirect to the admin assignment template' do
          make_request(@default_params.merge({:operator_id => 66}))
          response.should redirect_to(admin_assignment_url(@mock_assignment))
        end
        
      end

      describe 'if the operator can be found' do 
        
        before do 
          Operator.stub!(:find).with("66").and_return(@mock_operator)
        end
        
        describe 'if the location is a route' do 
        
          it 'should add a route operator to the route' do 
            @route_operators.should_receive(:build).with({:operator => @mock_operator})
            make_request(@default_params.merge({:operator_id => 66}))
          end
        
        end
        
        describe 'if the location is a stop area' do 
        
          before do 
            @mock_problem.stub!(:location).and_return(@stop_area)
          end
          
          it 'should add a stop area operator to the stop area' do 
            @stop_area_operators.should_receive(:build).with({:operator => @mock_operator})
            make_request(@default_params.merge({:operator_id => 66}))
          end
          
        end
        
        it 'should set the operator on the problem' do 
          @mock_problem.should_receive(:operator=).with(@mock_operator)
          make_request(@default_params.merge({:operator_id => 66}))
        end
        

        it 'should save the assignment, location and problem' do 
          @mock_assignment.should_receive(:save!)
          @route.should_receive(:save!)
          @mock_problem.should_receive(:save!)
          make_request(@default_params.merge({:operator_id => 66}))
        end
        
        
        describe 'if there is an error saving the models' do 
          
          before do 
            @mock_assignment.stub!(:save!).and_raise("some model error")
          end
          
          it 'should put the error message in the error flash' do 
            make_request(@default_params.merge({:operator_id => 66}))
            flash[:error].should == "some model error"
          end
          
          it 'should redirect to the admin assignment template' do
            make_request(@default_params.merge({:operator_id => 66}))
            response.should redirect_to(admin_assignment_url(@mock_assignment))
          end
          
        end
        
        describe 'if no email address is given' do        
          
          before do
            data = {:organization_name => 'Test Operator', 
                    :organization_email => '',
                    :location_only => false}
            @mock_assignment.stub!(:data).and_return(data)
          end   

          describe 'if there is a valid address for this location for the existing operator' do 
            
            before do 
              @mock_contact = mock_model(OperatorContact, :email => 'existing@example.com')
              @mock_operator.should_receive(:contact_for_category_and_location).with('Other', @route, false).and_return(@mock_contact)
            end
            
            it 'should show a success message in the flash' do 
              make_request(@default_params.merge({:operator_id => 66}))
              flash[:notice].should == "The assignment has been marked as complete."
            end
            
            it 'should redirect to the show template' do 
              make_request(@default_params.merge({:operator_id => 66}))
              response.should redirect_to(admin_assignment_url(@mock_assignment))
            end
            
            it 'should set the assignment as complete' do 
              @mock_assignment.should_receive(:status=).with(:complete)
              make_request(@default_params.merge({:operator_id => 66}))
            end
            
            it 'should mark the "write-to-transport-operator" assignment for the problem as complete' do 
              Assignment.should_receive(:complete_problem_assignments)
              make_request(@default_params.merge({:operator_id => 66}))
            end
          end
          
          describe 'if there is no valid address for the existing operator' do 
            it 'should show an error message in the flash' do 
              make_request(@default_params.merge({:operator_id => 66}))
              flash[:error].should ==  "The operator data has been added. There isn't a contact email, so the assignment is not complete."
            end
          end
    
        end
    
        describe 'if an email address is given' do 
          
          before do
            data = {:organization_name => 'Test Operator', 
                    :organization_email => 'test@example.com',
                    :location_only => false}
            @mock_assignment.stub!(:data).and_return(data)
          end   
    
          describe 'if the email is not already the contact address for this location for the operator' do 
            
            before do 
              @mock_operator.stub!(:contact_for_category_and_location).with('Other', @route, false).and_return(nil)
            end
            
            describe 'if the operator has no existing contact for this location' do 
            
              it 'should add a contact for the operator' do 
                @operator_contacts.should_receive(:build).with(:email => 'test@example.com', :category => "Other")
                make_request(@default_params.merge({:operator_id => 66}))
              end
              
            end
            
            describe 'if the operator has an existing contact for this location' do 
              
              before do 
                @mock_contact = mock_model(OperatorContact, :email => 'existing@example.com',
                                                            :location => nil,
                                                            :email= => true,
                                                            :save! => true)
                @mock_operator.should_receive(:contact_for_category_and_location).with('Other', @route, false).and_return(@mock_contact)
              end
            
              describe ' if the override_contact param is not set' do
                
                it 'should display an error' do 
                  make_request(@default_params.merge({:operator_id => 66}))
                  response.flash[:error].should == "Do you want to overwrite the existing email existing@example.com?"
                end
                
                 it 'should render the "show" template' do 
                   make_request(@default_params.merge({:operator_id => 66}))
                   response.should render_template('show')
                 end
              end
              
              describe 'if the override_contact param is set' do 
                
                it 'should replace the contact for the operator' do
                  @mock_contact.should_receive(:email=).with('test@example.com')
                  make_request(@default_params.merge({:operator_id => 66, :override_contact => '1'}))
                end
                
                it 'should set the assignment as complete' do 
                  @mock_assignment.should_receive(:status=).with(:complete)
                  make_request(@default_params.merge({:operator_id => 66, :override_contact => '1'}))
                end

                it 'should mark the "write-to-transport-operator" assignment for the problem as complete' do 
                  Assignment.should_receive(:complete_problem_assignments)
                  make_request(@default_params.merge({:operator_id => 66, :override_contact => '1'}))
                end
                
              end
              
              describe 'if the override_contact param is false' do 
                
                it 'should set the assignment as complete' do 
                  @mock_assignment.should_receive(:status=).with(:complete)
                  make_request(@default_params.merge({:operator_id => 66, :override_contact => '0' }))
                end

                it 'should mark the "write-to-transport-operator" assignment for the problem as complete' do 
                  Assignment.should_receive(:complete_problem_assignments)
                  make_request(@default_params.merge({:operator_id => 66, :override_contact => '0'}))
                end
                
              end
              
            end
            
          end
      
        end
      end
      
    end
    
    describe 'if no operator id param is present' do 
    
      it 'should redirect to the admin assignment url' do 
        make_request
        response.should redirect_to(controller.admin_url(admin_assignment_path(@mock_assignment)))
      end
      
    end
    
  end

end