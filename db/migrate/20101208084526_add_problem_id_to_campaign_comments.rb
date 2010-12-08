class AddProblemIdToCampaignComments < ActiveRecord::Migration
  def self.up
    add_column :campaign_comments, :problem_id, :integer
  end

  def self.down
    remove_column :campaign_comments, :problem_id
  end
end
