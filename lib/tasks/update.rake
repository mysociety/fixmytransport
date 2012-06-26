require 'fixmytransport/replayable_changes'
include FixMyTransport::ReplayableChanges

namespace :update do

  desc 'Load a new generation of transport data. Will run in dryrun mode unless DRYRUN=0 is specified.
        Sepcify verbose output with VERBOSE=1.'
  task :all => :environment do

    Rake::Task['update:create_data_generation'].execute

    # Load NPTG data
    Rake::Task['update:nptg'].execute

    ENV['MODEL'] = 'LocalityLink'
    Rake::Task['update:replay_updates'].execute

    # LOAD NAPTAN DATA
    Rake::Task['update:naptan'].execute

    # Replay updates to stops, stop areas
    ENV['MODEL'] = 'Stop'
    Rake::Task['update:replay_updates'].execute

    ENV['MODEL'] = 'StopArea'
    Rake::Task['update:replay_updates'].execute

    ENV['MODEL'] = 'StopAreaMembership'
    Rake::Task['update:replay_updates'].execute

    ENV['MODEL'] = 'StopAreaLink'
    Rake::Task['update:replay_updates'].execute

    # LOAD NOC DATA
    Rake::Task['update:noc'].execute

    # UPDATE PTEs, PTE areas to current generation
    Rake::Task['update:ptes'].execute
    Rake::Task['update:pte_areas'].execute

    ENV['MODEL'] = 'StopAreaOperator'
    Rake::Task['update:replay_updates'].execute

    # LOAD TNDS DATA
    Rake::Task['update:tnds'].execute

    ENV['MODEL'] = 'Route'
    Rake::Task['update:replay_updates'].execute

    ENV['MODEL'] = 'RouteOperator'
    Rake::Task['update:replay_updates'].execute


    # Rake::Task['naptan:post_load:mark_metro_stops'].execute

    # Mark records as loaded
    Rake::Task['db:mark_loaded'].execute

  end

  desc "Create a new data generation. Runs in dryrun mode unless DRYRUN=0
        is specified."
  task :create_data_generation => :environment do
    dryrun = check_dryrun()
    verbose = check_verbose()
    puts "Creating a new data generation..." if verbose

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
    Rake::Task['nptg:geo:convert_localities'].execute

    ENV['FILE'] = File.join(MySociety::Config.get('NPTG_DIR', ''), 'LocalityHierarchy.csv')
    Rake::Task['nptg:update:locality_links'].execute
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

    ENV['FILE'] = File.join(MySociety::Config.get('NAPTAN_DIR', ''), 'AreaHierarchy.csv')
    Rake::Task['naptan:update:stop_area_links'].execute

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

    ENV['MODEL'] = 'Operator'
    Rake::Task['update:replay_updates'].execute

    ENV['FILE'] = File.join(MySociety::Config.get('NOC_DIR', ''), 'station_operators.txt')
    Rake::Task['noc:update:station_operators'].execute
    Rake::Task['noc:update:stop_operators'].execute
  end

  desc 'Update TNDS data to the current generation. Runs in dryrun mode unless DRYRUN=0
        is specified. Verbose flag set by VERBOSE=1'
  task :tnds => :environment do
    ENV['DIR'] = MySociety::Config.get('TNDS_DIR', '')

    # Iterate through routes to be loaded, produce file of stops that can't be found
    Rake::Task['tnds:preload:list_unmatched_stops'].execute

    # Iterate through the routes to be loaded, produce file of operators that can't
    # be matched by operator code
    Rake::Task['tnds:preload:list_unmatched_operators'].execute
    Rake::Task['tnds:preload:load_unmatched_operators'].execute
    Rake::Task['tnds:load:routes'].execute
    Rake::Task['tnds:update:train_routes'].execute
    Rake::Task['tnds:update:find_previous_routes'].execute
  end

  desc 'Display a list of updates that have been made to instances of a model in the previous generation.
        Default behaviour is to only show updates that have been marked as replayable.
        Specify ALL=1 to see all updates. Specify model class as MODEL=ModelName.
        Specify a particular day as DATE=2012-04-23. Verbose flag set by VERBOSE=1'
  task :show_updates => :environment do
    check_for_model()
    verbose = check_verbose()
    model = ENV['MODEL'].constantize
    only_replayable = (ENV['ALL'] == "1") ? false : true
    update_hash = get_updates(model, only_replayable=only_replayable, ENV['DATE'], verbose)
    update_hash.each do |persistent_id, changes|
      changes.each do |details_hash|
        version_id = details_hash[:version_id]
        event = details_hash[:event]
        date = details_hash[:date]
        changes = details_hash[:changes]
        puts "#{version_id} #{date} #{event}: #{persistent_id} - #{changes.inspect}"
      end
    end
  end

  desc 'Generates an update file suitable for sending back to the source data provider from
        the changes that have been made locally to a particular model. Verbose flag set by VERBOSE=1.'
  task :create_update_file => :environment do
    check_for_model()
    verbose = check_verbose()
    model = ENV['MODEL'].constantize
    options = model.data_generation_options_hash
    change_list = replay_updates(model, dryrun=true, verbose=verbose)
    outfile = File.open("data/#{model}_changes_#{Date.today.to_s(:db)}.tsv", 'w')
    headers = ['Change type']
    identity_fields = model.external_identity_fields
    identity_fields.each do |identity_field|
      if identity_field.is_a? Symbol
        headers << identity_field
      elsif identity_field.is_a?(Hash)
        if identity_field.keys.size > 1
          raise "More than one key in hash passed to fields_to_attribute_hash"
        end
        association_name = identity_field.keys.first
        identity_field[association_name].each do |secondary_field|
          headers << "#{association_name.to_s.titleize} #{secondary_field}"
        end
      end
    end
    headers += ["Data"]
    outfile.write(headers.join("\t")+"\n")
    change_list.each do |change_info|
      change_event = change_info[:event]
      instance = change_info[:model]
      changes = change_info[:changes]
      data_row = [change_event.to_s]
      changes_to_write = {}
      if options[:ignore_in_file_output_fields] && changes
        changes.each do |attribute, change|
          if !options[:ignore_in_file_output_fields].include?(attribute)
            changes_to_write[attribute] = change
          end
        end
      else
        changes_to_write = changes
      end
      if change_event == :update && changes_to_write.empty?
        next
      end
      identity_fields.each do |identity_field|
        if identity_field.is_a? Symbol
          data_row << instance.send(identity_field)
        elsif identity_field.is_a?(Hash)
          if identity_field.keys.size > 1
            raise "More than one key in hash passed to fields_to_attribute_hash"
          end
          association_name = identity_field.keys.first
          identity_field[association_name].each do |secondary_field|
            association = instance.send(association_name)
            value = association.send(secondary_field)
            data_row << value
          end
        end

      end
      data_row << changes_to_write.inspect
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

  desc "Update passenger transport executive models to the current generation. Runs in dryrun mode
        unless DRYRUN=0 is specified. Verbose flag set by VERBOSE=1"
  task :ptes => :environment do
    dryrun = check_dryrun()
    verbose = check_verbose()
    PassengerTransportExecutive.in_generation(PREVIOUS_GENERATION).find_each() do |pte|
      puts "Cloning #{pte.name} to generation #{CURRENT_GENERATION}" if verbose
      new_gen_pte = PassengerTransportExecutive.clone_in_current_generation(pte)
      if ! new_gen_pte.valid?
        puts "ERROR: New instance is invalid:"
        puts new_gen_pte.errors.full_messages.join("\n")
        exit(1)
      end
      if ! dryrun
        new_gen_pte.save!
      end
    end
  end

  desc "Update passenger transport executive area models to the current generation. Runs in dryrun mode
        unless DRYRUN=0 is specified. Verbose flag set by VERBOSE=1"
  task :pte_areas => :environment do
    dryrun = check_dryrun()
    verbose = check_verbose()
    PassengerTransportExecutiveArea.in_generation(PREVIOUS_GENERATION).find_each() do |pte_area|
      puts "Cloning #{pte_area.id} to generation #{CURRENT_GENERATION}" if verbose
      new_gen_pte_area = PassengerTransportExecutiveArea.clone_in_current_generation(pte_area)
      new_gen_pte_area.update_association_to_current_generation(:pte, verbose)
      if ! new_gen_pte_area.valid?
        puts "ERROR: New instance is invalid:"
        puts new_gen_pte_area.errors.full_messages.join("\n")
        exit(1)
      end
      if ! dryrun
        new_gen_pte_area.save!
      end
    end
  end

  desc 'Look for operators that have responsibilities, but no record in the current data generation.
        Clone them from the previous generation and set their status as "DEL". Runs in dryrun mode
        unless DRYRUN=0 is specified. Verbose flag set by VERBOSE=1'
  task :deleted_operators => :environment do
    dryrun = check_dryrun()
    verbose = check_verbose()
    # Look for responsibilities where the organization type is operator and the persistent
    # id doesn't exist in the current generation
    cloned_persistent_ids = []
    Responsibility.find_each(:conditions => ["organization_type = 'Operator'
                                              AND organization_persistent_id not in
                                               (SELECT persistent_id
                                                FROM operators
                                                WHERE generation_low <= ?
                                                AND generation_high >= ?)",
                                                CURRENT_GENERATION, CURRENT_GENERATION]) do |responsibility|
      next if cloned_persistent_ids.include?(responsibility.organization_persistent_id)
      cloned_persistent_ids << responsibility.organization_persistent_id
      previous_operator = Operator.in_generation(PREVIOUS_GENERATION).find_by_persistent_id(responsibility.organization_persistent_id)
      raise "No previous operator for persistent_id #{responsibility.organization_persistent_id}" unless previous_operator
      puts "Cloning #{previous_operator.name} into current generation with 'DEL' status" if verbose
      new_operator = Operator.clone_in_current_generation(previous_operator)
      new_operator.status = 'DEL'
      if ! new_operator.valid?
        puts "ERROR: New instance is invalid:"
        puts new_operator.errors.full_messages.join("\n")
        exit(1)
      end
      if ! dryrun
        new_operator.save!
      end
    end
  end

  desc 'Look for locations that have problem reports, but no record in the current data generation.
        Clone them from the previous generation and set their status as "DEL". Runs in dryrun mode
        unless DRYRUN=0 is specified. Verbose flag set by VERBOSE=1'
  task :deleted_locations => :environment do
    dryrun = check_dryrun()
    verbose = check_verbose()
    cloned_persistent_ids = []
    location_types = [Stop, StopArea, Route]
    location_types.each do |location_type|
      Problem.find_each(:conditions => ["location_type = ?
                                         AND location_persistent_id not in
                                        (SELECT persistent_id
                                         FROM #{location_type.to_s.tableize}
                                         WHERE generation_low <= ?
                                         AND generation_high >= ?)",
                                         location_type.to_s,
                                         CURRENT_GENERATION,
                                         CURRENT_GENERATION]) do |problem|
        next if cloned_persistent_ids.include?(problem.location_persistent_id)
        previous_location = location_type.in_generation(PREVIOUS_GENERATION).find_by_persistent_id(problem.location_persistent_id)
        raise "No previous #{location_type} for persistent_id #{problem.location_persistent_id}" unless previous_location
        puts "Cloning #{previous_location.name} into current generation with 'DEL' status" if verbose
        new_location = location_type.clone_in_current_generation(previous_location)
        new_location.status = 'DEL'
        if ! new_location.valid?
          puts "ERROR: New instance is invalid:"
          puts new_location.errors.full_messages.join("\n")
          exit(1)
        end
        if ! dryrun
          new_location.save!
        end
      end
    end
  end

  desc 'Look for campaigns at locations where the organizations responsible for the location have changed,
        and the organizations listed as responsible for the campaign are no longer in the organizations
        responsible for the location. Runs in dryrun mode unless DRYRUN=0 is specified.'
  task :campaigns_at_locations_with_changed_operators => :environment do
    dryrun = check_dryrun()
    verbose = check_verbose()

    # Only looking for Routes or StopAreas as these are updated from external data
    Problem.find_each(:conditions => ["campaign_id IS NOT NULL
                                       AND (location_type = 'Route'
                                            OR location_type = 'StopArea')"]) do |problem|

      next if problem.campaign.status == :fixed
      next if (problem.campaign.status == :new && problem.created_at < Time.now - 1.month)
      location = problem.location
      location_class = problem.location_type.constantize
      next unless location.operators_responsible?

      previous_location = location_class.in_generation(PREVIOUS_GENERATION).find_by_persistent_id(location.persistent_id)
      if ! previous_location
        puts "#{location_class} for problem #{problem.id} has no previous #{location_class}"
        next
      end

      current_ids = location.operators.map{ |operator| operator.persistent_id }
      previous_ids = previous_location.operators.map{ |operator| operator.persistent_id }
      ids = problem.responsible_operators.map{ |operator| operator.persistent_id }
      names = problem.responsible_operators.map{ |operator| operator.name }.to_sentence
      in_current_location_resps = ids.any?{ |operator_id| current_ids.include?(operator_id) }
      in_previous_location_resps = ids.any?{ |operator_id| previous_ids.include?(operator_id) }
      if in_previous_location_resps && ! in_current_location_resps
        puts "#{location_class} #{location.id} no longer run by #{names}, listed as responsible for problem #{problem.id}"
        problem.campaign.handle_location_responsibility_change(location.operators, dryrun, verbose)
      end
    end

  end

end