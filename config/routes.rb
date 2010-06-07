ActionController::Routing::Routes.draw do |map|

  # home page
  map.root :controller => 'problems', :action => 'new'

  # resources
  map.resources :stories, :controller => 'problems', 
                          :except => [:update, :edit, :create], 
                          :collection => {:choose_location => :get, :find => :post, :recent => :get}

  map.resources :routes, :only => [:show], 
                         :collection => {:random => :get}, 
                         :member => {:respond => :get}

  map.resources :stops, :only => [:show], 
                        :collection => {:random => :get}, 
                        :member => {:respond => :get}

  map.resources :stop_areas, :only => [:show], 
                             :collection => {:random => :get}, 
                             :member => {:respond => :get}

  # static
  map.about '/about', :controller => 'static', :action => 'about'
  
  # admin
  map.namespace :admin do |admin|
    admin.root :controller => 'home'
    admin.resources :location_searches, :only => [:index, :show]
    admin.resources :routes, :only => [:index, :show, :update ]
  end
  
end
