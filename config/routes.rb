ActionController::Routing::Routes.draw do |map|

  # home page
  map.root :controller => 'problems', :action => 'frontpage'
  map.alternative_root '/home', :controller => 'problems', :action => 'frontpage'

  # operator pages
  map.operator_by_initial "/operators/:initial_char", :action => 'index',
                                            :controller => 'operators',
                                            :initial_char => /./
  map.resources :operators, :only => [:index, :show],
                            :member => { :issues => [:get],
                                         :routes => [:get],
                                         :stations => [:get]}  
  # subscriptions
  map.confirm_unsubscribe '/u/:email_token', :action => 'confirm_unsubscribe',
                                            :controller => 'subscriptions'
  map.unsubscribe '/unsubscribe', :action => 'unsubscribe',
                                  :controller => 'subscriptions',
                                  :conditions => { :method => :post }
  map.subscribe '/subscribe', :action => 'subscribe',
                              :controller => 'subscriptions',
                              :conditions => { :method => :post }

  # campaigns
  map.confirm_leave '/l/:email_token', :action => 'confirm_leave', :controller => 'campaigns'
  map.resources :campaigns, :except => [:destroy],
                            :member => { :join => [:get, :post],
                                         :leave => [:post],
                                         :add_update => [:get, :post],
                                         :add_comment => [:get, :post],
                                         :get_supporters => [:get],
                                         :complete => [:post],
                                         :add_photos => [:get, :post],
                                         :facebook => [:get],
                                         :add_details => [:get, :post],
                                         :share => [:get] } do |campaign|
    campaign.resources :incoming_messages, :only => [:show]
    campaign.attachment '/incoming_messages/:id/attach/:url_part_number', :action => 'show_attachment',
                                                                          :controller => 'incoming_messages'
    campaign.resources :outgoing_messages, :only => [:new, :show, :create]
    campaign.resources :assignments, :only => [:new, :create, :update, :edit]
  end

  # problems
  map.resources :problems, :except => [:destroy, :edit, :update],
                           :member => {:convert => [:get, :post],
                                       :add_comment => [:get, :post] },
                           :collection => { :choose_location => :get,
                                            :find_stop => :get,
                                            :find_route => :get,
                                            :find_bus_route => :get,
                                            :find_train_route => :get,
                                            :find_ferry_route => :get,
                                            :find_other_route => :get,
                                            :existing => :get }

  # questionnaires
  map.questionnaire_fixed '/q/fixed', :action => 'creator_fixed',
                                      :controller => 'questionnaires',
                                      :conditions => { :method => [:get, :post] }
  map.questionnaire '/q/:email_token', :action => 'show',
                                       :controller => 'questionnaires',
                                       :conditions => { :method => :get }
  map.update_questionnaire '/q/:email_token', :action => 'update',
                                              :controller => 'questionnaires',
                                              :conditions => { :method => :post }



  # issues index
  map.issues '/issues', :action => 'issues_index', :controller => 'problems'
  map.browse_issues '/issues/browse', :action => 'browse', :controller => 'problems'

  map.browse_issues_atom_link '/issues/browse/atom_link/:zoom/:lat/:lon', :action => 'atom_link',
                                                                          :controller => 'problems',
                                                                          :conditions => { :method => :get },
                                                                          :requirements => { :zoom => /\d\d?/,
                                                                                             :lon => /[-+]?[0-9]*\.?[0-9]+/,
                                                                                             :lat => /[-+]?[0-9]*\.?[0-9]+/ }

  # stops
  map.add_comment_stop "/stops/:scope/:id/add_comment", :controller => "locations",
                                                        :action => 'add_comment_to_stop',
                                                        :conditions => { :method => [:get, :post] }

  map.stop "/stops/:scope/:id.:format", :controller => "locations",
                                :action => 'show_stop',
                                :conditions => { :method => :get }

  # stop areas
  map.add_comment_stop_area "/stop-areas/:scope/:id/add_comment", :controller => "locations",
                                                                  :action => 'add_comment_to_stop_area',
                                                                  :conditions => { :method => [:get, :post] }

  map.stop_area "/stop-areas/:scope/:id.:format", :controller => "locations",
                                                  :action => 'show_stop_area',
                                                  :type => :stop_area,
                                                  :conditions => { :method => :get }

  # bus stations
  map.add_comment_bus_station "/bus-stations/:scope/:id/add_comment", :controller => "locations",
                                                                      :action => 'add_comment_to_stop_area',
                                                                      :conditions => { :method => [:get, :post] }

  map.bus_station "/bus-stations/:scope/:id.:format", :controller => "locations",
                                                      :action => 'show_stop_area',
                                                      :type => :bus_station,
                                                      :conditions => { :method => :get }

  # stations
  map.add_comment_station "/stations/:scope/:id/add_comment", :controller => "locations",
                                                              :action => 'add_comment_to_stop_area',
                                                              :conditions => { :method => [:get, :post] }

  map.station "/stations/:scope/:id.:format", :controller => "locations",
                                              :action => 'show_stop_area',
                                              :type => :station,
                                              :conditions => { :method => :get }

  # ferry terminals
  map.add_comment_ferry_terminal  "/ferry-terminals/:scope/:id/add_comment", :controller => "locations",
                                                                             :action => 'add_comment_to_stop_area',
                                                                             :conditions => { :method => [:get, :post] }

  map.ferry_terminal "/ferry-terminals/:scope/:id.:format", :controller => "locations",
                                                            :action => 'show_stop_area',
                                                            :type => :ferry_terminal,
                                                            :conditions => { :method => :get }

  # routes and sub routes
  map.routes "/routes/", :controller => 'locations',
                         :action => "show_route_regions"

  map.add_comment_sub_route "/sub-routes/:id/add_comment", :controller => "locations",
                                                           :action => 'add_comment_to_sub_route',
                                                           :conditions => { :method => [:get, :post] }

  map.sub_route "/sub-routes/:id.:format", :controller => "locations",
                                           :action => 'show_sub_route',
                                           :conditions => { :method => :get }

  map.route_region "/routes/:id.:format", :controller => "locations",
                                          :action => 'show_route_region',
                                          :conditions => { :method => :get }

  map.add_comment_route "/routes/:scope/:id/add_comment", :controller => "locations",
                                                          :action => 'add_comment_to_route',
                                                          :conditions => { :method => [:get, :post] }

  map.route "/routes/:scope/:id.:format", :controller => "locations",
                                          :action => 'show_route',
                                          :conditions => { :method => :get }



  # other locations for maps
  map.locations "/locations/:zoom/:lat/:lon/:link_type", :controller => 'services',
                                              :action => 'in_area',
                                              :conditions => { :method => :get },
                                              :requirements => { :zoom => /\d\d?/,
                                                                 :lon => /[-+]?[0-9]*\.?[0-9]+/,
                                                                 :lat => /[-+]?[0-9]*\.?[0-9]+/,
                                                                 :link_type => /(problem|location)/}
  # little service url for getting request country
  map.request_country 'request_country', :controller => 'services',
                                         :action => 'request_country',
                                         :conditions => { :method => :get }

  # service url for getting info for nearest stop from lon/lat
  map.request_nearest_stop 'request_nearest_stop', :controller => 'problems',
                                           :action => 'request_nearest_stop',
                                           :conditions => { :method => :get }

  # user sessions
  map.login 'login', :controller => 'user_sessions', :action => 'new'
  map.logout 'logout', :controller => 'user_sessions', :action => 'destroy'
  map.resources :user_sessions, :collection => { :external => :post }

  # accounts
  map.edit_password_reset '/password_resets/:email_token/edit', :action => 'edit',
                                                                :controller => 'password_resets',
                                                                :conditions => { :method => :get }
  map.password_reset '/password_resets/:email_token', :action => 'update',
                                                      :controller => 'password_resets',
                                                      :conditions => { :method => :put }

  map.resources :password_resets, :except => [:show, :destroy, :edit, :update]
  map.resource :account, :except => [:index, :destroy, :show]
  map.account_index '/account', :action => 'new', :controller => 'accounts', :conditions => { :method => :get }
  map.confirm_account '/a/:email_token', :action => 'confirm', :controller => 'accounts'

  # user profiles
  map.resources :profiles, :only => [:show]

  # static
  map.advice '/advice', :controller => 'static', :action => 'advice'
  map.about '/about', :controller => 'static', :action => 'about'
  map.feedback '/feedback', :controller => 'static',
                            :action => 'feedback',
                            :conditions => { :method => [:get, :post] }
  map.facebook '/facebook', :controller => 'static', :action => 'facebook'
  map.howto '/howto', :controller => 'static', :action => 'howto'

  map.guide_index '/guides', :controller => 'static', :action => 'guide_index'
  map.guides '/guides/:guide', :controller => 'static', :action => 'show_guide'

  # admin
  map.namespace :admin do |admin|
    admin.root :controller => 'home'
    admin.login 'login', :controller => 'user_sessions', :action => 'new'
    admin.logout 'logout', :controller => 'user_sessions', :action => 'destroy'
    admin.resource :account, :only => [:edit, :update]
    admin.resources :user_sessions, :only => [:new, :create, :destroy]
    admin.resources :location_searches, :only => [:index, :show]
    admin.resources :routes, :collection => { :merge => [:get, :post], :compare => [:get, :post] }
    admin.resources :operators, :collection => { :merge => [:get, :post] , :assign_routes => [:get, :post]}
    admin.resources :ptes, :only => [:index, :show, :update]
    admin.resources :council_contacts, :only => [:show, :index, :new, :create, :update]
    admin.resources :operator_contacts, :only => [:show, :new, :create, :update]
    admin.resources :pte_contacts, :only => [:show, :new, :create, :update]
    admin.resources :stops
    admin.resources :stop_areas
    admin.resources :users, :only => [:show, :index, :update]
    admin.resources :problems, :only => [:show, :index, :update], :member => { :resend => [:post] }
    admin.resources :campaigns, :only => [:show, :index, :update]
    admin.resources :campaign_updates, :only => [:show, :update]
    admin.resources :assignments, :only => [:show], :member => { :check => [:post] }
    admin.resources :comments, :only => [:show, :update]
    admin.resources :incoming_messages, :only => [:show, :update, :destroy],
                                        :member => { :download => [:get],
                                                     :redeliver => [:post] }
    admin.connect "/autocomplete_for_operator_name", :controller => 'operators',
                                                     :action => 'autocomplete_for_name'
    admin.connect "/autocomplete_for_stop_name", :controller => 'stops',
                                                 :action => 'autocomplete_for_name'
    admin.connect "/autocomplete_for_locality_name", :controller => 'localities',
                                                 :action => 'autocomplete_for_name'
    admin.connect '/comment_league', :controller => 'users', :action => 'comment_league'

  end

end
