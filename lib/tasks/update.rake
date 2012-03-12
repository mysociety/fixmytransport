namespace :update do

  desc 'Load a new generation of transport data. Will run in dryrun mode unless DRYRUN=0 is specified'
  task :all => :environment do

    dryrun = check_dryrun()
    puts "Creating a new data generation..."

    check_new_generation()
    data_generation = DataGeneration.new(:name => 'Data Load' + Time.now.to_s,
                                         :description => 'Test data load',
                                         :id => CURRENT_GENERATION)
    if !dryrun
      data_generation.save!
      # update the slugs for all non-generation models to be visible in the new
      # data generation
      data_generation_models_with_slugs = [ 'AdminArea',
                                            'Locality',
                                            'Route',
                                            'Region',
                                            'Stop',
                                            'StopArea',
                                            'Operator' ]
      conn = Slug.connection
      data_generation_models = data_generation_models_with_slugs.map{ |model| conn.quote(model) }.join(",")
      conn.execute("UPDATE slugs
                    SET generation_high = #{data_generation.id}
                    WHERE sluggable_type
                    NOT in (#{data_generation_models})")
    end

    # LOAD NPTG DATA

    ENV['GENERATION'] = CURRENT_GENERATION
    ENV['FILE'] = File.join(MySociety::Config.get('NPTG_DIR', ''), 'Regions.csv')
    Rake::Task['nptg:update:regions']
    ENV['FILE'] = File.join(MySociety::Config.get('NPTG_DIR', ''), 'AdminAreas.csv')
    Rake::Task['nptg:update:admin_areas']
    ENV['FILE'] = File.join(MySociety::Config.get('NPTG_DIR', ''), 'Districts.csv')
    Rake::Task['nptg:update:districts']
    ENV['FILE'] = File.join(MySociety::Config.get('NPTG_DIR', ''), 'Localities.csv')
    Rake::Task['nptg:update:localities']

    ENV['MODEL'] = 'Locality'
    # N.B. Run this before loading stops or stop areas so that the scoping of those slugs doesn't
    # get out of sync with the rejigged locality slugs
    Rake::Task['update:normalize_slug_sequences']

    Rake::Task['nptg:geo:convert_localities']

    # Can just reuse the load code here - localities will be scoped by the current data generation
    ENV['FILE'] = File.join(MySociety::Config.get('NPTG_DIR', ''), 'LocalityHierarchy.csv')
    Rake::Task['nptg:load:locality_hierarchy']

    # LOAD NAPTAN DATA

    ENV['FILE'] = File.join(MySociety::Config.get('NAPTAN_DIR', ''), 'Stops.csv')
    Rake::Task['naptan:update:stops']
    Rake::Task['naptan:geo:convert_stops']

    ENV['FILE'] = File.join(MySociety::Config.get('NAPTAN_DIR', ''), 'Groups.csv')
    Rake::Task['naptan:update:stop_areas']
    Rake::Task['naptan:geo:convert_stop_areas']

    ENV['FILE'] = File.join(MySociety::Config.get('NAPTAN_DIR', ''), 'StopsInGroup.csv')
    Rake::Task['naptan:update:stop_area_memberships']

    # Can just reuse the load code here - stop areas will be scoped by the current data generation
    ENV['FILE'] = File.join(MySociety::Config.get('NAPTAN_DIR', ''), 'GroupsInGroup.csv')
    Rake::Task['naptan:load:stop_area_hierarchy']

    # Some post-load cleanup on NaPTAN data - add locality to stop areas, and any stops missing locality
    Rake::Task['naptan:post_load:add_locality_to_stops'].execute
    Rake::Task['naptan:post_load:add_locality_to_stop_areas'].execute
    
    # LOAD NOC DATA
    Rake::Task['noc:update:operators'].execute
    Rake::Task['noc:update:operator_codes'].execute
    Rake::Task['noc:update:vosa_licenses'].execute
    
    
    # Add some other data - Rail stop codes, metro stop flag
    Rake::Task['naptan:post_load:add_stops_codes'].execute
    Rake::Task['naptan:post_load:mark_metro_stops'].execute

  end

  desc 'Reorder any slugs that existed in the previous generation, but have been given a different
        sequence by the arbitrary load order'
  task :normalize_slug_sequences => :environment do
    check_for_model()
    check_for_generation()
    ENV['MODEL'].constantize.normalize_slug_sequences(ENV['GENERATION'].to_i)
  end

end