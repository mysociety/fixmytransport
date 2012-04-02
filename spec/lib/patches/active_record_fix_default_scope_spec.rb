require 'spec_helper'
describe 'Patched ActiveRecord models' do

  describe 'when eagerly loading associations from models with default scope defined' do 
    fixtures :routes, :operators, :route_operators
    
    it 'should return associated models that obey their own default scope when using eager loading
        on a query including a has many association if the conditions do not reference those associated 
        models' do 
      route = routes(:aldershot_807_bus)
      found_route = Route.find(:all, :conditions => ['id = ?', route.id], 
                                     :include => :route_operators).first
      # size is in fact using scope correctly in unpatched activerecord as it uses a separate 
      # query which is scoped correctly on the associated model. Length is incorrect in the
      # unpatched code as it returns the number of records - when the default scope for 
      # route_operator has not been applied, that includes the route_operator from the previous
      # generation
      found_route.route_operators.size.should == 1
      found_route.route_operators.length.should == 1
      found_route.route_operators.should == [ route_operators(:three) ]
    end
    
    it 'should return associated models that obey their default scope when using eager loading
        on a query including a has many association if the conditions reference those models' do 
      route = routes(:aldershot_807_bus)
      found_route = Route.find(:all, :include => :route_operators,
                                     :conditions => ['routes.id = ? 
                                                      AND route_operators.id IS NOT NULL', route.id]).first
      found_route.route_operators.size.should == 1
      found_route.route_operators.length.should == 1
      found_route.route_operators.should == [ route_operators(:three) ]
    end
    
    it 'should return associated models that obey their own default scope when using eager loading
        on has_many :through associations when the query does not reference those associated models' do
      route = routes(:aldershot_807_bus)
      found_route = Route.find(:all, :conditions => ['id = ?', route.id],
                                     :include => :operators).first
      found_route.operators.size.should == 1
      found_route.operators.length.should == 1
      found_route.operators.should == [ operators(:a_bus_company) ]
    end
    
    it 'should return associated models that object the default scope when using eager loading
        on has_many :through associations if the conditions reference those models' do 
      route = routes(:aldershot_807_bus)
      found_route = Route.find(:all, :include => :operators,
                                     :conditions => ['routes.id = ? 
                                                      AND operators.id IS NOT NULL', route.id]).first
      found_route.operators.size.should == 1
      found_route.operators.length.should == 1
      found_route.operators.should == [ operators(:a_bus_company) ]
    end
    
    it 'should return an associated model that obeys its own default scope when using eager loading on 
        a belongs_to association query when the query does not reference the associated model' do 
      route_operator = route_operators(:references_old)
      found_route_operator = RouteOperator.find(:all, :include => :operator, 
                                                      :conditions => ['id = ?', route_operator.id]).first
      found_route_operator.operator.should be_nil
    end
    
    it 'should return an associated model that obeys its own default scope when using eager loading on
        a belongs to association query that references the associated model in its conditions' do 
      route_operator = route_operators(:references_old)
      found_route_operator = RouteOperator.find(:all, :include => :operator, 
                                                      :conditions => ['route_operators.id = ?
                                                                       AND operators.id IS NOT NULL', 
                                                                       route_operator.id]).first
      # Any condition set on the associated model (which is out of scope) should mean that no
      # record is returned.
      found_route_operator.should be_nil
    end

  end
  
  
  
end
  
