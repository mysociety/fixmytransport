namespace :temp do
  
  desc 'Set the data generation on existing tables'
  task :set_data_generation => :environment do 
    # DataGeneration.create!(:name => "Initial data load", :description => 'Data load from NPTDR on site creation')
    Region.connection.execute("update regions set generation_low = 1, generation_high = 1")
    AdminArea.connection.execute("update admin_areas set generation_low = 1, generation_high = 1")
    District.connection.execute("update districts set generation_low = 1, generation_high = 1")
    Locality.connection.execute("update localities set generation_low = 1, generation_high = 1")
    Slug.connection.execute("update slugs set generation_low = 1, generation_high = 1")
  end
  
  
  
end
