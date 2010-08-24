ActionController::Routing::Routes.draw do |map|

  # home page
  map.root :controller => 'problems', :action => 'frontpage'

  # resources
  map.resources :campaigns, :except => [:destroy]
  
  map.resources :problems, :except => [:destroy], 
                           :collection => { :choose_location => :get, 
                                            :find => :post }
                           
  map.confirm '/p/:email_token', :action => 'confirm', :controller => 'problems'
  map.confirm_update '/u/:email_token', :action => 'confirm_update', :controller => 'problems'
  
  # stops
  map.random_stops "/stops/random.:format", :controller => "stops",
                                            :action => "random", 
                                            :conditions => { :method => :get }
                                            
  map.stop "/stops/:scope/:id.:format", :controller => "stops", 
                                :action => 'show', 
                                :conditions => { :method => :get }

  map.stop "/stops/:scope/:id.:format", :controller => "stops", 
                                :action => 'update', 
                                :conditions => { :method => :put }
  
  # stop areas
  map.random_stop_areas "/stop-areas/random.:format", :controller => "stop_areas",
                                                      :action => "random", 
                                                      :conditions => { :method => :get }  

  map.stop_area "/stop-areas/:scope/:id.:format", :controller => "stop_areas", 
                                                  :action => 'show', 
                                                  :conditions => { :method => :get }

  map.stop_area "/stop-areas/:scope/:id.:format", :controller => "stop_areas", 
                                                  :action => 'update', 
                                                  :conditions => { :method => :put }
  
  # routes 
  map.random_routes "/routes/random.:format", :controller => "routes",
                                              :action => "random", 
                                              :conditions => { :method => :get }
                                              
  map.route "/routes/:scope/:id.:format", :controller => "routes", 
                                          :action => 'show', 
                                          :conditions => { :method => :get }

  map.route "/routes/:scope/:id.:format", :controller => "routes", 
                                          :action => 'update', 
                                          :conditions => { :method => :put }
  
  # user sessions
  map.login 'login', :controller => 'user_sessions', :action => 'new'  
  map.logout 'logout', :controller => 'user_sessions', :action => 'destroy'
  map.resources :user_sessions
  
  # static
  map.about '/about', :controller => 'static', :action => 'about'
  map.feedback '/feedback', :controller => 'static', 
                            :action => 'feedback', 
                            :conditions => { :method => [:get, :post] }
  
  # admin
  map.namespace :admin do |admin|
    admin.root :controller => 'home'
    admin.resources :location_searches, :only => [:index, :show]
    admin.resources :routes, :collection => { :merge => [:get, :post] }
    admin.resources :operators, :collection => { :merge => [:get, :post] }
    admin.resources :stops 
    admin.connect "/autocomplete_for_operator_name", :controller => 'operators', 
                                                     :action => 'autocomplete_for_name'
    admin.connect "/autocomplete_for_stop_name", :controller => 'stops',
                                                 :action => 'autocomplete_for_name'
    admin.connect "/autocomplete_for_locality_name", :controller => 'localities',
                                                 :action => 'autocomplete_for_name'
  end
  
end
