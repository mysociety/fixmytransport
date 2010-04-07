ActionController::Routing::Routes.draw do |map|
  map.root :controller => 'home'
  map.resources :problems
end
