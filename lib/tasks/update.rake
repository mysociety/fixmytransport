require 'fixmytransport/replayable_changes'
include FixMyTransport::ReplayableChanges

namespace :update do

  desc 'Load a new generation of transport data. Will run in dryrun mode unless DRYRUN=0 is specified.
        Sepcify verbose output with VERBOSE=1.'
  task :all => :environment do

    Rake::Task['update:create_data_generation'].execute

    # Load NPTG data
    Rake::Task['update:nptg'].execute

    # LOAD NAPTAN DATA
    Rake::Task['update:naptan'].execute

    # Replay updates to stops, stop areas
    ENV['MODEL'] = 'Stop'
    Rake::Task['update:replay_updates']

    ENV['MODEL'] = 'StopArea'
    Rake::Task['update:replay_updates']

    # LOAD NOC DATA
    Rake::Task['update:noc'].execute

    ENV['MODEL'] = 'Operator'
    Rake::Task['update:replay_updates']

    # LOAD TNDS DATA
    Rake::Task['update:tnds']
    # Rake::Task['naptan:post_load:mark_metro_stops'].execute

  end

  desc "Create a new data generation."
  task :create_data_generation => :environment do
    dryrun = check_dryrun()
    puts "Creating a new data generation..."

    check_new_generation()
    data_generation = DataGeneration.new(:name => 'Data Update',
                                         :description => 'Update from official data sources',
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
  end

  desc "Update NPTG data to the current data generation. Runs in dryrun mode unless DRYRUN=0
        is specified. Verbose flag set by VERBOSE=1."
  task :nptg => :environment do
    ENV['GENERATION'] = CURRENT_GENERATION.to_s
    ENV['FILE'] = File.join(MySociety::Config.get('NPTG_DIR', ''), 'Regions.csv')
    puts "calling regions"
    Rake::Task['nptg:update:regions'].execute
    puts "called regions"
    ENV['FILE'] = File.join(MySociety::Config.get('NPTG_DIR', ''), 'AdminAreas.csv')
    Rake::Task['nptg:update:admin_areas'].execute
    ENV['FILE'] = File.join(MySociety::Config.get('NPTG_DIR', ''), 'Districts.csv')
    Rake::Task['nptg:update:districts'].execute
    ENV['FILE'] = File.join(MySociety::Config.get('NPTG_DIR', ''), 'Localities.csv')
    Rake::Task['nptg:update:localities'].execute
    ENV['MODEL'] = 'Locality'
    # N.B. Run this before loading stops or stop areas so that the scoping of those slugs doesn't
    # get out of sync with the rejigged locality slugs
    Rake::Task['update:normalize_slug_sequences'].execute
    Rake::Task['nptg:geo:convert_localities'].execute

    # Can just reuse the load code here - localities will be scoped by the current data generation
    ENV['FILE'] = File.join(MySociety::Config.get('NPTG_DIR', ''), 'LocalityHierarchy.csv')
    Rake::Task['nptg:load:locality_hierarchy'].execute
  end

  desc 'Update NaPTAN data to the current data generation. Runs in dryrun mode unless DRYRUN=0
        is specified. Verbose flag set by VERBOSE=1'
  task :naptan => :environment do
    ENV['GENERATION'] = CURRENT_GENERATION.to_s
    ENV['FILE'] = File.join(MySociety::Config.get('NAPTAN_DIR', ''), 'Stops.csv')
    Rake::Task['naptan:update:stops'].execute
    Rake::Task['naptan:geo:convert_stops'].execute

    ENV['FILE'] = File.join(MySociety::Config.get('NAPTAN_DIR', ''), 'StopAreas.csv')
    Rake::Task['naptan:update:stop_areas'].execute
    Rake::Task['naptan:geo:convert_stop_areas'].execute

    ENV['FILE'] = File.join(MySociety::Config.get('NAPTAN_DIR', ''), 'StopsInArea.csv')
    Rake::Task['naptan:update:stop_area_memberships'].execute

    # Can just reuse the load code here - stop areas will be scoped by the current data generation
    ENV['FILE'] = File.join(MySociety::Config.get('NAPTAN_DIR', ''), 'AreaHierarchy.csv')
    Rake::Task['naptan:load:stop_area_hierarchy'].execute

    # Some post-load cleanup on NaPTAN data - add locality to stop areas, and any stops missing locality
    Rake::Task['naptan:post_load:add_locality_to_stops'].execute
    Rake::Task['naptan:post_load:add_locality_to_stop_areas'].execute

    # Add some other data - Rail stop codes
    ENV['FILE'] = File.join(MySociety::Config.get('NAPTAN_DIR', ''), 'RailReferences.csv')
    Rake::Task['naptan:post_load:add_stops_codes'].execute

  end

  desc 'Update NOC data to the current data generation. Runs in dryrun mode unless DRYRUN=0
        is specified. Verbose flag set by VERBOSE=1'
  task :noc => :environment do
    ENV['GENERATION'] = CURRENT_GENERATION.to_s
    ENV['FILE'] = File.join(MySociety::Config.get('NOC_DIR', ''), 'NOC_DB.csv')
    Rake::Task['noc:update:operators'].execute
    Rake::Task['noc:update:operator_codes'].execute
    Rake::Task['noc:update:vosa_licenses'].execute
    Rake::Task['noc:update:operator_contacts'].execute
  end

  desc 'Update TNDS data to the current generation. Runs in dryrun mode unless DRYRUN=0
        is specified. Verbose flag set by VERBOSE=1'
  task :tnds => :environment do
    ENV['DIR'] = MySociety::Config.get('TNDS_DIR', '')
    # Iterate through the routes to be loaded, produce file of operators that can't
    # be matched by operator code
    Rake::Task['tnds:preload:list_unmatched_operators'].execute
    Rake::Task['tnds:preload:load_unmatched_operators'].execute
    Rake::Task['tnds:load:routes'].execute
    Rake::Task['tnds:update:train_routes'].execute
    Rake::Task['tnds:update:find_previous_routes'].execute
  end

  desc 'Display a list of updates that have been made to instances of a model.
        Default behaviour is to only show updates that have been marked as replayable.
        Specify ALL=1 to see all updates. Specify model class as MODEL=ModelName.
        Specify a particular day as DATE=2012-04-23. Verbose flag set by VERBOSE=1'
  task :show_updates => :environment do
    check_for_model()
    verbose = check_verbose()
    model = ENV['MODEL'].constantize
    only_replayable = (ENV['ALL'] == "1") ? false : true
    update_hash = get_updates(model, only_replayable=only_replayable, ENV['DATE'], verbose)
    update_hash.each do |identity, changes|
      identity_type = identity[:identity_type]
      identity_hash = identity[:identity_hash]
      changes.each do |details_hash|
        id = details_hash[:id]
        event = details_hash[:event]
        date = details_hash[:date]
        changes = details_hash[:changes]
        puts "#{id} #{date} #{event} #{identity_hash.inspect} #{changes.inspect}"
      end
    end
  end

  desc 'Generates an update file suitable for sending back to the source data provider from
        the changes that have been made locally to a particular model. Verbose flag set by VERBOSE=1.'
  task :create_update_file => :environment do
    check_for_model()
    verbose = check_verbose()
    model = ENV['MODEL'].constantize
    change_list = replay_updates(model, dryrun=true, verbose=verbose)
    outfile = File.open("data/#{model}_changes_#{Date.today.to_s(:db)}.tsv", 'w')
    headers = ['Change type']
    identity_fields = model.data_generation_options_hash[:identity_fields]
    significant_fields = model.data_generation_options_hash[:new_record_fields] +
                          model.data_generation_options_hash[:update_fields]
    identity_fields.each do |identity_field|
      headers << identity_field
    end
    headers += ["Attribute", "Old value", "New value", "Data"]
    outfile.write(headers.join("\t")+"\n")
    change_list.each do |change_info|
      change_event = change_info[:event]
      instance = change_info[:model]
      if change_event == :update
        attribute = change_info[:attribute]
        from_value = change_info[:from_value]
        to_value = change_info[:to_value]
        if attribute == :generation_high
          data_row = ["New"]
          identity_fields.each do |identity_field|
            data_row << ''
          end
          data_row += ['', '', '']
          new_instance_info = {}
          significant_fields.each do |field|
            value = instance.send(field)
            if value
              new_instance_info[field] = value
            end
          end
          data_row << new_instance_info.inspect
        elsif attribute == :coords
        elsif significant_fields.include?(attribute)
          data_row = ["Update"]
          identity_fields.each do |identity_field|
            data_row << instance.send(identity_field)
          end
          data_row += [attribute, from_value, to_value]
        end
      elsif change_event == :destroy
        data_row = ["Destroy"]
        identity_fields.each do |identity_field|
          data_row << instance.send(identity_field)
        end
      end
      outfile.write(data_row.join("\t")+"\n") if data_row
    end
    outfile.close
  end

  desc 'Apply the replayable local updates for a model class that is versioned in data generations.
        Runs in dryrun mode unless DRYRUN=0 is specified. Verbose flag set by VERBOSE=1'
  task :replay_updates => :environment do
    check_for_model()
    dryrun = check_dryrun()
    verbose = check_verbose()
    model = ENV['MODEL'].constantize
    replay_updates(model, dryrun, verbose)
  end

  desc "Mark as unreplayable local updates marked as replayable for a model class that refer to an
        instance that does not exist and is not referred to by subsequent versions or don't contain
        changes to any significant fields. Runs in dryrun mode unless DRYRUN=0 is specified. Verbose
        flag set by VERBOSE=1"
  task :mark_unreplayable => :environment do
    check_for_model()
    dryrun = check_dryrun()
    verbose = check_verbose()
    model = ENV['MODEL'].constantize
    mark_unreplayable(model, dryrun, verbose)
  end

  desc 'Reorder any slugs that existed in the previous generation, but have been given a different
        sequence by the arbitrary load order'
  task :normalize_slug_sequences => :environment do
    check_for_model()
    check_for_generation()
    ENV['MODEL'].constantize.normalize_slug_sequences(ENV['GENERATION'].to_i)
  end

end