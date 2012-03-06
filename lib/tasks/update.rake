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
    Rake::Task['update:normalize_slug_sequences']
    Rake::Task['nptg:geo:convert_localities']
      
    # Can just reuse the load code here - localities will be scoped by the current data generation
    Rake::Task['nptg:load:locality_hierarchy']
  end
  
  desc 'Reorder any slugs that existed in the previous generation, but have been given a different
        sequence by the arbitrary load order'
  task :normalize_slug_sequences => :environment do 
    check_for_model()
    model.constantize.normalize_slug_sequences
  end
  
end