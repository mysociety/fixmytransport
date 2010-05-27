namespace :db do 

  desc "Load all reference data into the database"
  task :populate => :environment do 
    Rake::Task['db:seed'].execute
    ENV['DIR'] = MySociety::Config.get('OPTION_NPTG_DIR', '')
    Rake::Task['nptg:load:all'].execute
    ENV['DIR'] = MySociety::Config.get('OPTION_NAPTAN_DIR', '')
    Rake::Task['naptan:load:all'].execute
    Rake::Task['naptan:convert:os_to_lat_lon '].execute
    ENV['DIR'] = File.join(MySociety::Config.get('OPTION_NPTDR_DIR', ''), 'routes')
    Rake::Task['nptdr:load:routes'].execute
  end

end
