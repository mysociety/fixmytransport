ActionController::Routing::Routes.draw do |map|
  map.root :controller => 'home'
  map.resources :problems, :except => [:update, :edit]
  map.resources :routes, :only => [:show], :collection => {:random => :get}
  map.resources :stops, :only => [:show], :collection => {:random => :get}
  map.resources :stop_areas, :only => [:show], :collection => {:random => :get}
end
