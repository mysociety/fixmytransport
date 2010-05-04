ActionController::Routing::Routes.draw do |map|
  map.root :controller => 'home'
  map.resources :problems, :except => [:update, :edit], :collection => {:choose_location => :get}
  map.resources :routes, :only => [:show], :collection => {:random => :get}
  map.resources :stops, :only => [:show], :collection => {:random => :get}
  map.resources :stop_areas, :only => [:show], :collection => {:random => :get}
end
