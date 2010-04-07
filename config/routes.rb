ActionController::Routing::Routes.draw do |map|
  map.root :controller => 'home'
  map.resources :problems, :except => [:update, :edit]
end
