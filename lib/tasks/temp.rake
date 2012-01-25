namespace :temp do
  
  desc 'Update campaign slugs that end in a trailing hyphen' 
  task :update_trailing_hyphen_slugs => :environment do 
  
    Campaign.visible.each do |campaign|
      if campaign.to_param.last == '-'
        campaign.save
      end
    end
    
  end
  
end
