ActionController::Routing::Routes.draw do |map|

  # home page
  map.root :controller => 'home'

  # resources
  map.resources :stories, :controller => 'problems', 
                          :except => [:update, :edit, :create], 
                          :collection => {:choose_location => :get, :find => :post}
  map.confirm '/c/:email_token', :action => 'confirm', :controller => 'problems'

  [:routes, :stops, :stop_areas].each do |location|
    map.resources location, :only => [:show, :update], 
                            :collection => {:random => :get}, 
                            :member => {:respond => :get}
  end

  # static
  map.about '/about', :controller => 'static', :action => 'about'
  map.feedback '/feedback', :controller => 'static', :action => 'feedback'
  
  # admin
  map.namespace :admin do |admin|
    admin.root :controller => 'home'
    admin.resources :location_searches, :only => [:index, :show]
    admin.resources :routes, :only => [:index, :show, :update ]
  end
  
end
