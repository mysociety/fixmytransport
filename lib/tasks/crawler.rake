namespace :crawler do

  def connect_to_site
    require 'net/http'
    require 'uri'
    include ActionController::UrlWriter
    include ApplicationHelper
    default_url_options[:host] = MySociety::Config.get("DOMAIN", 'localhost:3000')
    url = URI.parse(root_url)
    puts "HOST: #{url.host}"
    puts "PORT: #{url.port}"
    Net::HTTP.start(url.host, url.port) do |http|
      yield http
    end
  end

  def make_request(http, path)
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

  desc 'Spider the site route pages'
  task :routes => :environment do
    connect_to_site do |http|
      Route.current.find_each(:include => 'region') do |route|
        path = route_path(route.region, route)
        make_request(http, path)
      end
    end
  end

  desc 'Spider the site stop pages'
  task :stops => :environment do
    if ENV['START_ID']
      conditions = ['id > ?', ENV['START_ID']]
    else
      conditions = nil
    end
    connect_to_site do |http|
      Stop.current.find_each(:conditions => conditions, :include => 'locality') do |stop|
        path = stop_path(stop.locality, stop)
        make_request(http, path)
      end
    end
  end

  desc 'Spider the site stop area pages'
  task :stop_areas => :environment do
    connect_to_site do |http|
      StopArea.current.find_each(:include => 'locality', :conditions => ['area_type in (?)', StopAreaType.primary_types]) do |stop_area|
        path = location_path(stop_area)
        make_request(http, path)
      end
    end
  end

end