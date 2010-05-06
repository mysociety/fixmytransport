ActionController::Routing::Routes.draw do |map|

  map.root :controller => 'home'

  map.resources :places, :controller => 'problems', 
                         :except => [:update, :edit], 
                         :collection => {:choose_location_list => :get, 
                                         :choose_location_area => :get}

  map.resources :routes, :only => [:show], 
                         :collection => {:random => :get}, 
                         :member => {:respond => :get}

  map.resources :stops, :only => [:show], 
                        :collection => {:random => :get}, 
                        :member => {:respond => :get}

  map.resources :stop_areas, :only => [:show], 
                             :collection => {:random => :get}, 
                             :member => {:respond => :get}

end
