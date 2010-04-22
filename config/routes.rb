ActionController::Routing::Routes.draw do |map|
  map.root :controller => 'home'
  map.resources :problems, :except => [:update, :edit]
  map.resources :routes, :only => [:show]
  map.resources :stops, :only => [:show ]
end
