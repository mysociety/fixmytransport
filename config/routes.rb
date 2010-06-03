ActionController::Routing::Routes.draw do |map|

  map.root :controller => 'problems', :action => 'new'

  map.resources :places, :controller => 'problems', 
                         :except => [:update, :edit], 
                         :collection => {:choose_location => :get}

  map.resources :routes, :only => [:show], 
                         :collection => {:random => :get}, 
                         :member => {:respond => :get}

  map.resources :stops, :only => [:show], 
                        :collection => {:random => :get}, 
                        :member => {:respond => :get}

  map.resources :stop_areas, :only => [:show], 
                             :collection => {:random => :get}, 
                             :member => {:respond => :get}

  map.namespace :admin do |admin|
    admin.root :controller => 'home'
    admin.resources :location_searches, :only => [:index, :show]
    admin.resources :routes, :only => [:index, :show, :update ]
  end
  
end
