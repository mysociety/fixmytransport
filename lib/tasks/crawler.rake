namespace :crawler do 

  desc 'Spider the site route pages' 
  task :routes => :environment do 
    require 'open-uri'
    include ActionController::UrlWriter
    default_url_options[:host] = MySociety::Config.get("DOMAIN", '127.0.0.1:3000')
    Route.find_each(:include => 'region') do |route|
      open(route_url(route.region, route))
    end
  end
  
end