namespace :db do 

  desc "Load all reference data into the database"
  task :populate => :environment do 
    
    # Load transport modes
    Rake::Task['db:seed'].execute
    
    # Load Localities, Regions, Districts, AdminAreas
    ENV['DIR'] = MySociety::Config.get('NPTG_DIR', '')
    Rake::Task['nptg:load:all'].execute
    
    # Load Stops, StopAreas, give StopAreas lat/lon
    ENV['DIR'] = MySociety::Config.get('NAPTAN_DIR', '')
    Rake::Task['naptan:load:all'].execute
    Rake::Task['naptan:geo:convert_stop_areas'].execute
    
    # Load Routes
    ENV['DIR'] = File.join(MySociety::Config.get('NPTDR_DIR', ''), 'routes')
    Rake::Task['nptdr:load:routes'].execute
    
    # Delete stop areas without stops, add locality 
    Rake::Task['naptan:post_load:delete_unpopulated_stop_areas'].execute
    Rake::Task['naptan:post_load:add_locality_to_stop_areas'].execute
    
    # Delete routes with no stops, add localities and regions
    Rake::Task['nptdr:post_load:delete_routes_without_stops'].execute
    Rake::Task['nptdr:post_load:add_route_localities'].execute
    Rake::Task['nptdr:post_load:add_route_regions'].execute
    
    # Generate slugs
    Rake::Task['friendly_id:make_slugs'].execute
  end
  
  desc 'Load data from a Postgres binary dump'
  task :load_from_binary => :environment do 
    check_for_file
    ENV['VERSION'] = '0'
    Rake::Task['db:migrate'].execute
    ENV['VERSION'] = ''
    Rake::Task['db:migrate'].execute
    ActiveRecord::Base.connection.execute('DELETE FROM geometry_columns;')
    ActiveRecord::Base.connection.execute('DELETE FROM spatial_ref_sys;')
    ActiveRecord::Base.connection.execute('DELETE FROM schema_migrations;')
    port = ActiveRecord::Base.configurations[RAILS_ENV]['port']
    database = ActiveRecord::Base.configurations[RAILS_ENV]['database']
    user = ActiveRecord::Base.configurations[RAILS_ENV]['user']
    system("pg_restore --port=#{port} --disable-triggers --data-only -d #{database} -U #{user} #{ENV['FILE']}")
  end

end
