namespace :crawler do 

  desc 'Spider the site route pages' 
  task :routes => :environment do 
    require 'net/http'
    require 'uri'
    include ActionController::UrlWriter
    default_url_options[:host] = MySociety::Config.get("DOMAIN", 'localhost:3000')
    url = URI.parse(root_url)
    puts "HOST: #{url.host}"
    puts "PORT: #{url.port}"
    Net::HTTP.start(url.host, url.port) do |http|
      Route.find_each(:include => 'region') do |route|
        path = route_path(route.region, route) 
        puts path
        req = Net::HTTP::Get.new(path)
        if MySociety::Config.get('APP_STATUS', 'live') == 'closed_beta'
          beta_username = MySociety::Config.get('BETA_USERNAME', 'username')
          unless ENV['PASSWORD']
            usage_message "usage: This task requires PASSWORD=[beta testing password]"
          end
          beta_password = ENV['PASSWORD']
          req.basic_auth beta_username, beta_password
        end
        response = http.request(req)
        puts response.code
      end
    end
  end
  
end