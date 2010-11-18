ActionController::Routing::Routes.draw do |map|

  # home page
  map.root :controller => 'problems', :action => 'frontpage'

  # resources
  map.resources :operators, :only => [:show]
  map.resources :campaigns, :except => [:destroy], 
                            :member => { :join => [:get, :post], 
                                         :leave => [:post], 
                                         :add_update => [:get, :post],
                                         :add_comment => [:get, :post] }
  map.confirm_join '/c/:email_token', :action => 'confirm_join', :controller => 'campaigns'
  map.confirm_leave '/l/:email_token', :action => 'confirm_leave', :controller => 'campaigns'

  map.resources :problems, :except => [:destroy], 
                           :collection => { :choose_location => :get, 
                                            :find_stop => :get,
                                            :find_route => :get, 
                                            :find_bus_route => :get,
                                            :find_train_route => :get,
                                            :find_other_route => :get }                           
  map.confirm '/p/:email_token', :action => 'confirm', :controller => 'problems'
  map.confirm_update '/u/:email_token', :action => 'confirm_update', :controller => 'problems'
  
  map.attachment '/incoming_messages/:id/attach/:url_part_number', :action => 'show_attachment', 
                                                                   :controller => 'incoming_messages'
  map.resources :incoming_messages, :only => [:show]

  
  # stops                                   
  map.stop "/stops/:scope/:id.:format", :controller => "locations", 
                                :action => 'show_stop', 
                                :conditions => { :method => :get }
  
  # stop areas
  map.stop_area "/stop-areas/:scope/:id.:format", :controller => "locations", 
                                                  :action => 'show_stop_area', 
                                                  :type => :stop_area,
                                                  :conditions => { :method => :get }
  
  map.bus_station "/bus-stations/:scope/:id.:format", :controller => "locations", 
                                                      :action => 'show_stop_area', 
                                                      :type => :bus_station,
                                                      :conditions => { :method => :get }
  
  map.station "/stations/:scope/:id.:format", :controller => "locations", 
                                              :action => 'show_stop_area', 
                                              :type => :station,
                                              :conditions => { :method => :get }

  map.ferry_terminal "/ferry-terminals/:scope/:id.:format", :controller => "locations", 
                                                            :action => 'show_stop_area', 
                                                            :type => :ferry_terminal,
                                                            :conditions => { :method => :get }

  # routes                                               
  map.route "/routes/:scope/:id.:format", :controller => "locations", 
                                          :action => 'show_route', 
                                          :conditions => { :method => :get }

  # other locations for maps
  map.locations "/locations/:zoom/:lat/:lon/:link_type", :controller => 'locations', 
                                              :action => 'in_area',
                                              :conditions => { :method => :get },
                                              :requirements => { :zoom => /\d\d?/,
                                                                 :lon => /[-+]?[0-9]*\.?[0-9]+/,
                                                                 :lat => /[-+]?[0-9]*\.?[0-9]+/,
                                                                 :link_type => /(problem|location)/}
  
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
    admin.resources :stop_areas 
    admin.connect "/autocomplete_for_operator_name", :controller => 'operators', 
                                                     :action => 'autocomplete_for_name'
    admin.connect "/autocomplete_for_stop_name", :controller => 'stops',
                                                 :action => 'autocomplete_for_name'
    admin.connect "/autocomplete_for_locality_name", :controller => 'localities',
                                                 :action => 'autocomplete_for_name'
  end
  
end
