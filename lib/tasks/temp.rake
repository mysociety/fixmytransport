namespace :temp do
  
  desc 'Move the associations on comments to a polymorphic field'
  task :make_comments_polymorphic => :environment do 
    Comment.find_each do |comment|
      puts "#{comment.id} #{comment.user_name}"
      if comment.campaign_update
        comment.commented = comment.campaign_update
      elsif comment.problem
        comment.commented = comment.problem
      else
        raise "Unknown commentable for comment #{comment.id}"
      end
      comment.save!
    end
  end
  
end