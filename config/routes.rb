ActionController::Routing::Routes.draw do |map|

  # home page
  map.root :controller => 'stories', :action => 'new'

  # resources
  map.resources :stories, :except => [:update, :edit, :create], 
                          :collection => {:choose_location => :get, :find => :post}
  map.confirm '/c/:email_token', :action => 'confirm', :controller => 'stories'
  
  # stops
  map.stop "/stops/:scope/:id.:format", :controller => "stops", 
                                :action => 'show', 
                                :conditions => { :method => :get }

  map.stop "/stops/:scope/:id.:format", :controller => "stops", 
                                :action => 'update', 
                                :conditions => { :method => :put }
  
  map.random_stops "/stops/random.:format", :controller => "stops",
                                            :action => "random", 
                                            :conditions => { :method => :get }

  map.respond_stop "/stops/:scope/:id/respond.:format", :controller => "stops", 
                                                        :action => "respond",
                                                        :conditions => { :method => :get }

  # stop areas
  map.stop_area "/stop-areas/:scope/:id.:format", :controller => "stop_areas", 
                                                  :action => 'show', 
                                                  :conditions => { :method => :get }

  map.stop_area "/stop-areas/:scope/:id.:format", :controller => "stop_areas", 
                                                  :action => 'update', 
                                                  :conditions => { :method => :put }
  
  map.random_stop_areas "/stop-areas/random.:format", :controller => "stop_areas",
                                                      :action => "random", 
                                                      :conditions => { :method => :get }

  map.respond_stop_area "/stop-areas/:scope/:id/respond.:format", :controller => "stop_areas", 
                                                                  :action => "respond",
                                                                  :conditions => { :method => :get }
  

  map.resources :routes, :only => [:show, :update], 
                          :collection => {:random => :get}, 
                          :member => {:respond => :get}

  # static
  map.about '/about', :controller => 'static', :action => 'about'
  map.feedback '/feedback', :controller => 'static', 
                            :action => 'feedback', 
                            :conditions => { :method => [:get, :post] }
  
  # admin
  map.namespace :admin do |admin|
    admin.root :controller => 'home'
    admin.resources :location_searches, :only => [:index, :show]
    admin.resources :routes, :only => [:index, :show, :update ]
  end
  
end
