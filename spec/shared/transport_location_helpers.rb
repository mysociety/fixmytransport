module SharedBehaviours
  
  module TransportLocationHelpers
    
    shared_examples_for "a transport location" do 
      
      def respond_to(expected)
       simple_matcher("respond_to #{expected}") { |given| given.respond_to?(expected) == true }
      end
      
      it 'should respond to the required methods ' do 
        required_methods = [:name,
                            :responsible_organizations,
                            :councils_responsible?, 
                            :pte_responsible?, 
                            :operators_responsible?]
        required_methods.each do |method|
          @instance.respond_to?(method).should(be_true)
        end
      end
            
    end
  end

end