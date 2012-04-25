CURRENT_GENERATION = MySociety::Config.get("CURRENT_GENERATION", "1")
PREVIOUS_GENERATION = CURRENT_GENERATION - 1

require 'fixmytransport/data_generations'
ActiveRecord::Base.send(:include, FixMyTransport::DataGenerations)